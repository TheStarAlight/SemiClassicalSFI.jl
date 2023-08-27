
using Printf
using Base.Threads
using SpecialFunctions
using StaticArrays
using Random
using Rotations
using WignerD
"Sample provider which generates initial electron samples using the MO-ADK method."
struct MOADKSampler <: ElectronSampleProvider
    laser   ::Laser;
    target  ::Molecule; # MO-ADK only supports [Molecule]
    monte_carlo;
    t_samples;
    ss_kd_samples;
    ss_kz_samples;
    mc_kt_num;
    mc_kt_max;
    cutoff_limit;
    phase_method;   # currently supports :CTMC, :QTMC, :SCTS.
    rate_prefix;    # supports :Exp, :Full or a combination of {:Pre|:PreCC, :Jac}.
    ion_orbit_idx;

    function MOADKSampler(;
                            laser               ::Laser,
                            target              ::SAEAtomBase,
                            sample_t_intv       ::Tuple{<:Real,<:Real},
                            sample_t_num        ::Integer,
                            sample_cutoff_limit ::Real,
                            sample_monte_carlo  ::Bool,
                            traj_phase_method   ::Symbol,
                            rate_prefix         ::Union{Symbol,AbstractVector{Symbol},AbstractSet{Symbol}},
                            mol_orbit_idx       ::Integer,
                                #* for step-sampling (!rate_monteCarlo)
                            ss_kd_max           ::Real,
                            ss_kd_num           ::Integer,
                            ss_kz_max           ::Real,
                            ss_kz_num           ::Integer,
                                #* for Monte-Carlo-sampling (rate_monteCarlo)
                            mc_kt_num           ::Integer,
                            mc_kt_max           ::Real,
                            kwargs...   # kwargs are surplus params.
                            )
        # check phase method support.
        if ! (traj_phase_method in [:CTMC, :QTMC, :SCTS])
            error("[MOADKSampler] Undefined phase method [$traj_phase_method].")
            return
        end
        # check rate prefix support.
        if isa(rate_prefix, Symbol) # Exp or Full
            if rate_prefix == :Exp
                rate_prefix = []
            elseif rate_prefix == :Full
                rate_prefix = [:PreCC, :Jac]
            else
                error("[MOADKSampler] Undefined tunneling rate prefix [$rate_prefix].")
                return
            end
        else # a list containing Pre|PreCC, Jac.
            if length(rate_prefix) == 0
                rate_prefix = :Exp
            elseif ! mapreduce(*, p->in(p,[:Pre,:PreCC,:Jac]), rate_prefix)
                error("[MOADKSampler] Undefined tunneling rate prefix [$rate_prefix].")
                return
            elseif :Pre in rate_prefix && :PreCC in rate_prefix
                error("[MOADKSampler] Rate prefixes [Pre] & [PreCC] conflict.")
                return
            end
        end
        # check sampling parameters.
        @assert (sample_t_num>0) "[MOADKSampler] Invalid time sample number $sample_t_num."
        @assert (sample_cutoff_limit≥0) "[MOADKSampler] Invalid cut-off limit $sample_cutoff_limit."
        if ! sample_monte_carlo # check SS sampling parameters.
            @assert (ss_kd_num>0 && ss_kz_num>0) "[MOADKSampler] Invalid kd/kz sample number $ss_kd_num/$ss_kz_num."
        else                    # check MC sampling parameters.
            @assert (sample_t_intv[1] < sample_t_intv[2]) "[MOADKSampler] Invalid sampling time interval $sample_t_intv."
            @assert (mc_kt_num>0) "[MOADKSampler] Invalid sampling kt_num $mc_kt_num."
            @assert (mc_kt_max>0) "[MOADKSampler] Invalid sampling kt_max $mc_kt_max."
        end
        # check molecular orbital
        if ! (mol_orbit_idx in MolAsympCoeffAvailableIndices(target))
            MolCalcAsympCoeff!(target, mol_orbit_idx)
        end
        if MolEnergyLevels(target)[MolHOMOIndex(target)+mol_orbit_idx] ≤ 0
            error("[MOADKSampler] The energy of the ionizing orbit is non-negative.")
        end
        # check Keldysh parameter.
        F0 = LaserF0(laser)
        Ip = IonPotential(target)
        γ0 = AngFreq(laser) * sqrt(2Ip) / F0
        if γ0 ≥ 0.5
            @warn "[MOADKSampler] Keldysh parameter γ=$(@sprintf "%.4f" γ0), adiabatic (tunneling) condition [γ<<1] not sufficiently satisfied."
        elseif γ0 ≥ 1.0
            @warn "[MOADKSampler] Keldysh parameter γ=$(@sprintf "%.4f" γ0), adiabatic (tunneling) condition [γ<<1] unsatisfied."
        end
        # finish initialization.
        return if ! sample_monte_carlo
            new(laser,target,
                sample_monte_carlo,
                range(sample_t_intv[1],sample_t_intv[2];length=sample_t_num),
                range(-abs(ss_kd_max),abs(ss_kd_max);length=ss_kd_num), range(-abs(ss_kz_max),abs(ss_kz_max);length=ss_kz_num),
                0,0,        # for MC params. pass empty values
                sample_cutoff_limit,traj_phase_method,rate_prefix,mol_orbit_idx)
        else
            t_samples = sort!(rand(MersenneTwister(1), sample_t_num) .* (sample_t_intv[2]-sample_t_intv[1]) .+ sample_t_intv[1])
            new(laser,target,
                sample_monte_carlo,
                t_samples,
                0:0,0:0,    # for SS params. pass empty values
                mc_kt_num, mc_kt_max,
                sample_cutoff_limit,traj_phase_method,rate_prefix,mol_orbit_idx)
        end
    end
end

"Gets the total number of batches."
function batch_num(sp::MOADKSampler)
    return length(sp.t_samples)
end

"Generates a batch of electrons of `batchId` from `sp` using MO-ADK method."
function gen_electron_batch(sp::MOADKSampler, batchId::Int)
    t = sp.t_samples[batchId]
    Fx::Function = LaserFx(sp.laser)
    Fy::Function = LaserFy(sp.laser)
    Fxt = Fx(t)
    Fyt = Fy(t)
    Ft = hypot(Fxt,Fyt)
    F0 = LaserF0(sp.laser)
    φ  = atan(-Fyt,-Fxt)   # direction of tunneling exit, which is opposite to F.
    Z  = AsympNuclCharge(sp.target)
    Ip = IonPotential(sp.target, sp.ion_orbit_idx)
    asymp_coeff = MolAsympCoeff(sp.target, sp.ion_orbit_idx)
    lMax = MolAsympCoeff_lMax(sp.target, sp.ion_orbit_idx)
    γ0  = AngFreq(sp.laser) * sqrt(2Ip) / F0
    prefix = sp.rate_prefix
    @inline ADKAmpExp(F,Ip,kd,kz) = exp(-(kd^2+kz^2+2*Ip)^1.5/3F)
    cutoff_limit = sp.cutoff_limit
    if Ft == 0 || ADKAmpExp(Ft,Ip,0.0,0.0)^2 < cutoff_limit
        return nothing
    end

    # determining Euler angles (α,β,γ)
    mol_rot = MolRotation(sp.target)
    α,β,γ = obtain_Euler(mol_rot, (Fxt,Fyt))

    # determining ionization amplitude (contains phase)
    amplitude::Function =
    begin
        κ = sqrt(2Ip)
        n = Z/κ # n* = Z/κ
        c = 2^(n/2+1) * κ^(2n+1/2) * gamma(n/2+1) # i^(3(1-n)/2) is omitted, trivial
        e0 = 2.71828182845904523
        c_cc = 2^(3n/2+1) * κ^(5n+1/2) * Ft^(-n) * (1+2γ0/e0)^(-n)
        @inline ti(kd,kz) = sqrt(κ^2+kd^2+kz^2)/Ft
        @inline k_ts(kx,ky,kz,ti) = (kx,ky,kz) .- 1im*ti*(Fxt,Fyt,0.0)
        # C_lm = asymp_coeff[l+1,m+l+1]
        pre(kx,ky,kd,kz) = c * mapreduce((l,m,m_) -> asymp_coeff[l+1,m+l+1] * WignerD.wignerDjmn(l,m_,m, α,β,γ) * sph_harm_lm_khat(l,m_, k_ts(kx,ky,kz,ti(kd,kz)), (Fxt,Fyt)), +, [(l,m,m_) for l in 0:lMax, m in -l:l, m_ in -l:l]) / ((kd^2+kz^2)*Ft^2)^((n+1)/4)
        pre_cc(kx,ky,kd,kz) = c_cc * mapreduce((l,m,m_) -> asymp_coeff[l+1,m+l+1] * WignerD.wignerDjmn(l,m_,m, α,β,γ) * sph_harm_lm_khat(l,m_, k_ts(kx,ky,kz,ti(kd,kz)), (Fxt,Fyt)), +, [(l,m,m_) for l in 0:lMax, m in -l:l, m_ in -l:l]) / ((kd^2+kz^2)*Ft^2)^((n+1)/4)
        jac = Ft
        step(range) = (maximum(range)-minimum(range))/length(range) # gets the step length of the range
        dkdt = if ! sp.monte_carlo
            step(sp.t_samples) * step(sp.ss_kd_samples) * step(sp.ss_kz_samples)
        else
            step(sp.t_samples) * π*sp.mc_kt_max^2/sp.mc_kt_num
        end

        # returns
        if isempty(prefix)
            rate_exp(kx,ky,kd,kz) = sqrt(dkdt) * ADKAmpExp(Ft,Ip,kd,kz)
        else
            if :Pre in prefix
                if :Jac in prefix
                    rate_pre_jac(kx,ky,kd,kz) = sqrt(dkdt) * ADKAmpExp(Ft,Ip,kd,kz) * pre(kx,ky,kd,kz) * jac
                else
                    rate_pre(kx,ky,kd,kz) = sqrt(dkdt) * ADKAmpExp(Ft,Ip,kd,kz) * pre(kx,ky,kd,kz)
                end
            elseif :PreCC in prefix
                if :Jac in prefix
                    rate_precc_jac(kx,ky,kd,kz) = sqrt(dkdt) * ADKAmpExp(Ft,Ip,kd,kz) * pre_cc(kx,ky,kd,kz) * jac
                else
                    rate_precc(kx,ky,kd,kz) = sqrt(dkdt) * ADKAmpExp(Ft,Ip,kd,kz) * pre_cc(kx,ky,kd,kz)
                end
            else # [:Jac]
                rate_jac(kx,ky,kd,kz) = sqrt(dkdt) * ADKAmpExp(Ft,Ip,kd,kz) * jac
            end
        end
    end

    phase_method = sp.phase_method
    dim = (phase_method == :CTMC) ? 8 : 9 # x,y,z,kx,ky,kz,t0,rate[,phase]

    sample_count_thread = zeros(Int,nthreads())
    init_thread = if ! sp.monte_carlo
        zeros(Float64, dim, nthreads(), length(sp.ss_kd_samples)*length(sp.ss_kz_samples)) # initial condition (support for multi-threading)
    else
        zeros(Float64, dim, nthreads(), sp.mc_kt_num)
    end

    if ! sp.monte_carlo
        kd_samples = sp.ss_kd_samples
        kz_samples = sp.ss_kz_samples
        kdNum, kzNum = length(kd_samples), length(kz_samples)
        @threads for ikd in 1:kdNum
            for ikz in 1:kzNum
                kd0, kz0 = kd_samples[ikd], kz_samples[ikz]
                kx0 = kd0*-sin(φ)
                ky0 = kd0* cos(φ)
                r0 = (Ip+(kd0^2+kz0^2)/2)/Ft
                x0 = r0*cos(φ)
                y0 = r0*sin(φ)
                z0 = 0.0
                amp = amplitude(kx0,ky0,kd0,kz0)
                rate = abs2(amp)
                if rate < cutoff_limit
                    continue    # discard the sample
                end
                sample_count_thread[threadid()] += 1
                init_thread[1:8,threadid(),sample_count_thread[threadid()]] = [x0,y0,z0,kx0,ky0,kz0,t,rate]
                if phase_method != :CTMC
                    init_thread[9,threadid(),sample_count_thread[threadid()]] = angle(amp)
                end
            end
        end
    else
        @threads for i in 1:sp.mc_kt_num
            # generates random (kd0,kz0) inside circle kd0^2+kz0^2=ktMax^2.
            rng = Random.MersenneTwister(0)
            kd0, kz0 = gen_rand_pt_circ(rng, sp.mc_kt_max)
            kx0 = kd0*-sin(φ)
            ky0 = kd0* cos(φ)
            r0 = (Ip+(kd0^2+kz0^2)/2)/Ft
            x0 = r0*cos(φ)
            y0 = r0*sin(φ)
            z0 = 0.0
            amp = amplitude(kx0,ky0,kd0,kz0)
            rate = abs2(amp)
            if rate < cutoff_limit
                continue    # discard the sample
            end
            sample_count_thread[threadid()] += 1
            init_thread[1:8,threadid(),sample_count_thread[threadid()]] = [x0,y0,z0,kx0,ky0,kz0,t,rate]
            if phase_method != :CTMC
                init_thread[9,threadid(),sample_count_thread[threadid()]] = angle(amp)
            end
        end
    end
    if sum(sample_count_thread) == 0
        # @warn "[MOADKSampler] All sampled electrons are discarded in batch #$(batchId), corresponding to t=$t."
        return nothing
    end
    # collect electron samples from different threads.
    init = zeros(Float64, dim, sum(sample_count_thread))
    N = 0
    for i in 1:nthreads()
        init[:,N+1:N+sample_count_thread[i]] = init_thread[:,i,1:sample_count_thread[i]]
        N += sample_count_thread[i]
    end
    return init
end
