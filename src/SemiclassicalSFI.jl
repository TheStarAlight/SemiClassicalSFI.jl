
"""
**SemiclassicalSFI.jl**
Implementation of classical/semiclassical trajectory methods in strong-field ionization of atoms and molecules.
"""
module SemiclassicalSFI

using OrdinaryDiffEq
using LinearAlgebra
using StaticArrays
using Parameters
using HDF5
using Dates
using ProgressMeter
using YAML, OrderedCollections
using Pkg

include("Lasers/Lasers.jl")
include("Targets/Targets.jl")
include("ElectronSamplers/ElectronSamplers.jl")
using .Lasers
using .Targets
using .ElectronSamplers

export performSFI, Lasers, Targets

"""
Performs a semiclassical simulation with given parameters.

# Parameters

## Required params. for all:
- `init_cond_method = <:ADK|:SFA|:SFAAE|:WFAT|:MOADK>`  : Method of electrons' initial conditions. Currently supports `:ADK`, `:SFA`, `:SFAAE` for atoms and `:WFAT`, `:MOADK` for molecules.
- `laser::Laser`                                        : Parameters of the laser field.
- `target::Target`                                      : Parameters of the target.
- `sample_t_intv = (start,stop)`                        : Time interval in which the initial electrons are sampled.
- `sample_t_num`                                        : Number of time samples.
- `traj_t_final`                                        : Time when every trajectory simulation ends.
- `final_p_max = (pxMax,pyMax,pzMax)`                   : Boundaries of final momentum spectrum collected in three dimensions.
- `final_p_num = (pxNum,pyNum,pzNum)`                   : Numbers of final momentum spectrum collected in three dimensions.

## Required params. for step-sampling methods:
- `ss_kd_max`   : Boundary of kd (momentum's transversal component in the polarization (xy) plane) samples.
- `ss_kd_num`   : Number of kd (momentum's transversal component in the polarization (xy) plane) samples.
- `ss_kz_max`   : Boundary of kz (momentum's component along propagation direction (z ax.)) samples.
- `ss_kz_num`   : Number of kz (momentum's component along propagation direction (z ax.)) samples (an even number is required).

## Required params. for Monte-Carlo-sampling methods:
- `mc_kt_num`   : Number of kt (initial momentum which is perpendicular to field direction, two dimensional) samples in a single time sample.
- `mc_kd_max`   : Boundary of kd.
- `mc_kz_max`   : Boundary of kz.

## Optional params. for all:
- `save_path`                                       : Output HDF5 file path.
- `save_3D_spec = false`                            : Determines whether the 3D momentum spectrum is saved (if not, will only save 2D by flattening on the xy plane) (default `false`).
- `traj_phase_method = <:CTMC|:QTMC|:SCTS>`         : Method of classical trajectories' phase (default `CTMC`).
- `traj_rtol = 1e-6`                                : Relative error tolerance when solving classical trajectories using adaptive methods (default `1e-6`).
- `sample_cutoff_limit = 1e-16`                     : The cut-off limit of the probability of the sampled electron, electrons with probabilities lower than the limit would be discarded.
- `sample_monte_carlo = false`                      : Determines whether Monte-Carlo sampling is used when generating electron samples (default `false`). Currently only supports ADK.

## Optional params. for atomic SFA, SFA-AE and ADK methods:
- `rate_prefix = <:Full|[:Pre|:PreCC, :Jac]|:Exp>`  : Prefix of the exponential term in the ionization rate (default `:Full`).

## Optional params. for target `Molecule`:
- `mol_orbit_idx = 0`   : Index of the ionizing orbit relative to the HOMO (e.g., `0` indicates HOMO, and `-1` indicates HOMO-1) (default `0`).

## Optional params. for atomic ADK method:
- `adk_tun_exit = <:IpF|:FDM|:Para>` : Tunneling exit method for atomic ADK methods (when `init_cond_method==:ADK`) (default `:IpF`).

"""
function performSFI(; # some abbrs.:  req. = required, opt. = optional, params. = parameters.
                        #* req. params. for all methods
                    init_cond_method    ::Symbol,
                    laser               ::Laser,
                    target              ::Target,
                    sample_t_intv       ::Tuple{<:Real,<:Real},
                    sample_t_num        ::Integer,
                    traj_t_final        ::Real,
                    final_p_max         ::Tuple{<:Real,<:Real,<:Real},
                    final_p_num         ::Tuple{<:Int,<:Int,<:Int},
                        #* req. params. for step-sampling (ss) methods
                    ss_kd_max           ::Real      = 0.,
                    ss_kd_num           ::Integer   = 0 ,
                    ss_kz_max           ::Real      = 0.,
                    ss_kz_num           ::Integer   = 0 ,
                        #* req. params. for Monte-Carlo (mc) methods
                    mc_kt_num           ::Integer   = 0 ,
                    mc_kd_max           ::Real      = 0.,
                    mc_kz_max           ::Real      = 0.,
                        #* opt. params. for all methods
                    save_path           ::String    = default_filename(),
                    save_3D_spec        ::Bool      = false,
                    traj_phase_method   ::Symbol    = :CTMC,
                    traj_rtol           ::Real      = 1e-6,
                    sample_cutoff_limit ::Real      = 1e-16,
                    sample_monte_carlo  ::Bool      = false,
                        #* opt. params. for SFA, SFA-AE and ADK methods
                    rate_prefix         ::Union{Symbol,AbstractVector{Symbol},AbstractSet{Symbol}} = :Full,
                        #* opt. params. for target `MoleculeBase`
                    mol_orbit_idx       ::Integer   = 0,
                        #* opt. params. for ADK method
                    adk_tun_exit        ::Symbol    = :IpF
                    )
    #* check parameters
    if !sample_monte_carlo && isodd(ss_kz_num)
        @warn "[performSFI] ss_kz_num=$(ss_kz_num) is an odd number, which may result in anomalous final electron states. Please choose an even number to avoid such problem."
    end
    # check the path in the first
    if isfile(save_path)
        @warn "[performSFI] File \"$save_path\" already exists, will save at \"$(default_filename())\"."
        save_path = default_filename()
    end
    # create the file, try to write and lock it
    file = h5open(save_path * "!", "w")
    file["info"] = "Trajectory simulation output generated by SemiclassicalSFI @ $(get_SCSFI_version())"
    #* pack up all parameters.
    kwargs = Dict{Symbol,Any}()
    @pack! kwargs= (init_cond_method, laser, target, sample_t_intv, sample_t_num, traj_t_final, final_p_max, final_p_num,
                    ss_kd_max, ss_kd_num, ss_kz_max, ss_kz_num,
                    mc_kt_num, mc_kd_max, mc_kz_max,
                    traj_phase_method, traj_rtol, sample_cutoff_limit, sample_monte_carlo, rate_prefix,
                    mol_orbit_idx,
                    adk_tun_exit)
    #* initialize sample provider.
    sp::ElectronSampler = init_sampler(;kwargs...)
    #* launch electrons and summarize.
    #   * prepare storage
    nthreads = Threads.nthreads()
    # ionization amplitude (ion_prob_final is for final data, ion_prob_sum_temp & ion_prob_collect is for temporary cache)
    ion_prob_final, ion_prob_sum_temp, ion_prob_collect =
        if traj_phase_method == :CTMC
            zeros(Float64, final_p_num),     zeros(Float64, final_p_num),     zeros(Float64, tuple(final_p_num...,nthreads))
        else
            zeros(ComplexF64, final_p_num),  zeros(ComplexF64, final_p_num),  zeros(ComplexF64, tuple(final_p_num...,nthreads))
        end
    # classical prob
    classical_prob = Dict{Symbol,Float64}()
        classical_prob[:ion]                = 0.
        classical_prob[:ion_uncollected]    = 0.
    #   * launch electrons and collect
    batchNum = batch_num(sp)
    prog1 = ProgressUnknown(dt=0.2, desc="Launching electrons and collecting...", color = :cyan, spinner = true)
    prog2 = Progress(batch_num(sp); dt=0.2, color = :cyan, barlen = 25, barglyphs = BarGlyphs('[', '●', ['◔', '◑', '◕'], '○', ']'), showspeed = true, offset=1)
    n_eff_traj = 0  # number of effective trajectories that are launched.
    for batchId in 1:batch_num(sp)
        init = gen_electron_batch(sp, batchId)
        if ! isnothing(init)
            n_eff_traj += size(init,2)
            launch_and_collect!(init,
                                ion_prob_final, ion_prob_sum_temp, ion_prob_collect,
                                classical_prob; kwargs...)
        end
        next!(prog1,spinner=raw"-\|/",desc="Launching electrons and collecting ... [batch #$batchId/$batchNum, $(n_eff_traj) electrons collected]"); next!(prog2);
    end
    finish!(prog1); finish!(prog2); println();
    if traj_phase_method != :CTMC
        ion_prob_final = abs2.(ion_prob_final)
    end
    #* save as HDF5.
    begin
        dict_out = OrderedDict{Symbol,Any}()
        # package version
        dict_out[:version] = get_SCSFI_version()
        # req. params. for all
        dict_out[:init_cond_method]     = init_cond_method
        dict_out[:laser]                = Lasers.Serialize(laser)
        dict_out[:target]               = Targets.Serialize(target)
        dict_out[:sample_t_intv]        = sample_t_intv
        dict_out[:sample_t_num]         = sample_t_num
        dict_out[:traj_t_final]         = traj_t_final
        dict_out[:final_p_max]          = final_p_max
        dict_out[:final_p_num]          = final_p_num
        if ! sample_monte_carlo
            # req. params. for step-sampling (ss) methods
            dict_out[:ss_kd_max]        = ss_kd_max
            dict_out[:ss_kd_num]        = ss_kd_num
            dict_out[:ss_kz_max]        = ss_kz_max
            dict_out[:ss_kz_num]        = ss_kz_num
        else
            # req. params. for Monte-Carlo (mc) methods
            dict_out[:mc_kt_num]        = mc_kt_num
            dict_out[:mc_kd_max]        = mc_kd_max
            dict_out[:mc_kz_max]        = mc_kz_max
        end
        # opt. params. for all methods
        dict_out[:save_path]            = save_path
        dict_out[:save_3D_spec]         = save_3D_spec
        dict_out[:traj_phase_method]    = traj_phase_method
        dict_out[:traj_rtol]            = traj_rtol
        dict_out[:sample_cutoff_limit]  = sample_cutoff_limit
        dict_out[:sample_monte_carlo]   = sample_monte_carlo
        # opt. params. for SFA, SFA-AE and ADK methods
        if init_cond_method in [:SFA, :SFAAE, :ADK, :MOSFA, :MOSFAAE, :MOADK]
            dict_out[:rate_prefix]      = rate_prefix
        end
        # opt. params. for target `MoleculeBase`
        if typeof(target) <: Targets.MoleculeBase
            dict_out[:mol_orbit_idx]    = mol_orbit_idx
        end
        # opt. params. for ADK method
        if init_cond_method == :ADK
            dict_out[:adk_tun_exit]     = adk_tun_exit
        end
        yaml_out = YAML.write(dict_out)
        file["abstract"] = yaml_out
    end
    file["px"] = collect(range(-final_p_max[1],final_p_max[1], length=final_p_num[1]))
    file["py"] = collect(range(-final_p_max[2],final_p_max[2], length=final_p_num[2]))
    if save_3D_spec
        file["pz"] = collect(range(-final_p_max[3],final_p_max[3], length=final_p_num[3]))
        file["momentum_spec_3D", shuffle=true, deflate=6] = ion_prob_final    # the output is compressed, level from 1 to 9. successful @ HDF5 v0.16.15
    end
    file["momentum_spec_2D", shuffle=true, deflate=6] = reshape(sum(ion_prob_final, dims=3),size(ion_prob_final)[1:2])    # the output is compressed, level from 1 to 9.
    file["ion_prob"] = classical_prob[:ion]
    file["ion_prob_uncollected"] = classical_prob[:ion_uncollected]
    file["num_effective_traj"] = n_eff_traj
    close(file)
    mv(save_path * "!", save_path)
    @info "Task finished, data saved at \"$(save_path)\"."
end


function launch_and_collect!( init,
                            ion_prob_final,
                            ion_prob_sum_temp,
                            ion_prob_collect,
                            classical_prob;
                            laser               ::Laser,
                            target              ::Target,
                            traj_t_final        ::Real,
                            traj_phase_method   ::Symbol,
                            traj_rtol           ::Real,
                            final_p_max         ::Tuple{<:Real,<:Real,<:Real},
                            final_p_num         ::Tuple{<:Int,<:Int,<:Int},
                            kwargs...   # kwargs are surplus params.
                            )
    Ip                  = IonPotential(target)
    Fx::Function        = LaserFx(laser)
    Fy::Function        = LaserFy(laser)
    targetF::Function   = TargetForce(target)
    targetP::Function   = TargetPotential(target)
    nucl_charge         = AsympNuclCharge(target)
    traj::Function      = TrajectoryFunction(target, Fx,Fy,traj_phase_method)
    batch_size = size(init,2)
    warn_num = 0    # number of warnings of anomalous electrons.
    max_warn_num = 5
    nthreads = Threads.nthreads()
    class_prob_ion              = zeros(nthreads)
    class_prob_ion_uncollected  = zeros(nthreads)

    # create ODE problem and solve the ensemble.
    prob_dim = (traj_phase_method == :CTMC) ? 6 : 7 # x,y,z,px,py,pz[,phase]
    traj_ODE_prob::ODEProblem = ODEProblem(traj, (@SVector zeros(Float64,prob_dim)), Float64.((0,traj_t_final)))
    init_traj::Function =
        if prob_dim == 6
            (prob,i,repeat) -> remake(prob; u0=SVector{6}([init[k,i] for k in 1:6]),     tspan = (init[7,i],Float64(traj_t_final)))
        else
            (prob,i,repeat) -> remake(prob; u0=SVector{7}([init[k,i] for k in [1:6;9]]), tspan = (init[7,i],Float64(traj_t_final)))
        end
    ensemble_prob::EnsembleProblem = EnsembleProblem(traj_ODE_prob, prob_func=init_traj, safetycopy=false)
    sol = solve(ensemble_prob, OrdinaryDiffEq.Tsit5(), EnsembleThreads(), trajectories=batch_size, adaptive=true, dt=0.01, reltol=traj_rtol, save_everystep=false)
    # collect and summarize.
    Threads.@threads for i in 1:batch_size
        threadid = Threads.threadid()
        x0,y0,z0,px0,py0,pz0 = sol.u[i].u[ 1 ][1:6]
        x, y, z, px, py, pz  = sol.u[i].u[end][1:6]
        if px^2+py^2+pz^2>100  # possibly anomalous electron, intercept and cancel.
            warn_num += 1
            if warn_num < max_warn_num
                @warn "[Ensemble Simulation] Found electron with anomalously large momentum $([px,py,pz]), whose initial condition is r0=$([x0,y0,z0]), k0=$([px0,py0,pz0]), t0=$(sol.u[i].t[1])."
            elseif warn_num == max_warn_num
                @warn "[Ensemble Simulation] Found electron with anomalously large momentum $([px,py,pz]), whose initial condition is r0=$([x0,y0,z0]), k0=$([px0,py0,pz0]), t0=$(sol.u[i].t[1]). Similar warnings in the same batch would be suppressed."
            end
            continue
        end
        phase = (traj_phase_method == :CTMC) ? (0.) : (sol.u[i].u[end][7])
        prob = init[8,i]
        if traj_phase_method == :SCTS # asymptotic Coulomb phase correction term in SCTS
            sqrtb = (2Ip)^(-0.5)
            g = sqrt(1+2Ip*((y*pz-z*py)^2+(z*px-x*pz)^2+(x*py-y*px)^2))
            phase -= px0*x0+py0*y0+pz0*z0 + nucl_charge*sqrtb*(log(g)+asinh((x*py+y*py+z*pz)/(g*sqrtb)))
        end
        E_inf = (px^2+py^2+pz^2)/2 + targetP(x,y,z)
        r_vec = [x, y, z ]
        p_vec = [px,py,pz]
        L_vec = r_vec × p_vec
        L2    = sum(abs2.(L_vec))
        if E_inf ≥ 0    # finally ionized.
            class_prob_ion[threadid] += prob
            p_inf = sqrt(2E_inf)
            a_vec = p_vec × L_vec - nucl_charge * r_vec ./ norm(r_vec)
            p_inf_vec = (p_inf/(1+p_inf^2*L2)) .* (p_inf .* (L_vec×a_vec) - a_vec)
            if final_p_num[1]>1
                pxIdx = round(Int, (p_inf_vec[1]+final_p_max[1])/(final_p_max[1]/final_p_num[1]*2))
            else
                pxIdx = 1   # without this step, only electrons with positive p_x component would be collected, the same for p_y and p_z.
            end
            if final_p_num[2]>1
                pyIdx = round(Int, (p_inf_vec[2]+final_p_max[2])/(final_p_max[2]/final_p_num[2]*2))
            else
                pyIdx = 1
            end
            if final_p_num[3]>1
                pzIdx = round(Int, (p_inf_vec[3]+final_p_max[3])/(final_p_max[3]/final_p_num[3]*2))
            else
                pzIdx = 1
            end
            if checkbounds(Bool, ion_prob_collect, pxIdx,pyIdx,pzIdx, threadid)
                if traj_phase_method == :CTMC
                    ion_prob_collect[pxIdx,pyIdx,pzIdx, threadid] += prob # prob
                else
                    ion_prob_collect[pxIdx,pyIdx,pzIdx, threadid] += sqrt(prob)*exp(1im*phase) # sqrt(prob)*phase_factor
                end
            else
                class_prob_ion_uncollected[threadid] += prob
            end
        else # finally become rydberg.
            # currently does not support Rydberg collecting.
        end
    end
    sum!(ion_prob_sum_temp, ion_prob_collect)
    ion_prob_final .+= ion_prob_sum_temp
    classical_prob[:ion]                += sum(class_prob_ion)
    classical_prob[:ion_uncollected]    += sum(class_prob_ion_uncollected)
end

function default_filename()
    Y,M,D = yearmonthday(now())
    h,m,s = hour(now()), minute(now()), second(now())
    return "SCSFI-$(string(Y,pad=4))$(string(M,pad=2))$(string(D,pad=2))-$(string(h,pad=2))$(string(m,pad=2))$(string(s,pad=2)).h5"
end

function get_SCSFI_version()
    for (k,v::Pkg.API.PackageInfo) in Pkg.dependencies()
        if v.name == "SemiclassicalSFI"
            return v.version
        end
    end
end

end
