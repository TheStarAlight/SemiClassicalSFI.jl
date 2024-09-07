
"Represents a monochromatic elliptically polarized laser field with Cos2-shape envelope propagating in z direction."
struct Cos2Laser <: MonochromaticLaser
    "Peak intensity of the laser field (in W/cm^2)."
    peak_int;
    "Wavelength of the laser field (in nm)."
    wave_len;
    "Cycle number of the laser field."
    cyc_num;
    "Ellipticity of the laser field."
    ellip;
    "Azimuth angle of the laser's polarization's principle axis relative to x axis (in radians)."
    azi;
    "Carrier-Envelope-Phase (CEP) of the laser field."
    cep;
    "Time shift of the laser relative to the peak (in a.u.)."
    t_shift;
end

"""
    Cos2Laser(peak_int, wave_len|ang_freq, cyc_num|duration, ellip [, azi=0.0] [, cep=0.0] [, t_shift=0.0]) <: MonochromaticLaser

Initializes a new monochromatic elliptically polarized laser field with Cos2-shape envelope.

# Parameters
- `peak_int`    : Peak intensity of the laser field (numerically in **W/cm²** or a `Unitful.Quantity`).
- `wave_len`    : Wavelength of the laser field (numerically in **nm** or a `Unitful.Quantity`).
- `ang_freq`    : Angular frequency of the laser field (numerically in **a.u.** or a `Unitful.Quantity` of single-photon energy).
- `cyc_num`     : Number of cycles of the laser field.
- `duration`    : Duration of the laser field (numerically in **a.u.** or a `Unitful.Quantity`).
- `ellip`       : Ellipticity of the laser field [-1≤ε≤1, 0 indicates linear polarization and ±1 indicates circular polarization].
- `azi`         : Azimuth angle of the laser's polarization's principle axis relative to x axis (in **radians**) *(optional, default 0)*.
- `cep`         : Carrier-Envelope-Phase of the laser field *(optional, default 0)*.
- `t_shift`     : Time shift of the laser (numerically in **a.u.** or a `Unitful.Quantity`) relative to the peak *(optional, default 0)*.
"""
function Cos2Laser(;peak_int,
                    wave_len=0, ang_freq=0,   # must specify either wave_len or ang_freq.
                    cyc_num=0,  duration=0,   # must specify either cyc_num or duration.
                    ellip, azi=0., cep=0., t_shift=0.)
    # make conversions
    (peak_int isa Quantity) && (peak_int = uconvert(W/cm^2, peak_int).val)
    (wave_len isa Quantity) && (wave_len = uconvert(nm, wave_len).val)
    (ang_freq isa Quantity) && (ang_freq = (uconvert(eV, ang_freq) |> auconvert).val)
    (duration isa Quantity) && (duration = (uconvert(fs, duration) |> auconvert).val)
    (t_shift  isa Quantity) && (t_shift  = (uconvert(fs, t_shift)  |> auconvert).val)
    # ================
    @assert wave_len>0 || ang_freq>0    "[Cos2Laser] Must specify either `wave_len` or `ang_freq`."
    @assert cyc_num>0 || duration>0     "[Cos2Laser] Must specify either `cyc_num` or `duration`."
    if wave_len>0 && ang_freq>0
        @warn "[Cos2Laser] Both `wave_len` & `ang_freq` are specified, will use `wave_len`."
    end
    if cyc_num>0 && duration>0
        @warn "[Cos2Laser] Both `cyc_num` & `duration` are specified, will use `cyc_num`."
    end
    if wave_len==0
        wave_len = 45.563352525 / ang_freq
    else
        ang_freq = 45.563352525 / wave_len
    end
    if cyc_num==0
        cyc_num = duration / (2π/ang_freq)
    end
    Cos2Laser(peak_int, wave_len, cyc_num, ellip, azi, cep, t_shift)
end

"Gets the peak intensity of the laser field (in W/cm²)."
PeakInt(l::Cos2Laser) = l.peak_int
"Gets the wave length of the laser field (in nm)."
WaveLen(l::Cos2Laser) = l.wave_len
"Gets the cycle number of the laser field."
CycNum(l::Cos2Laser) = l.cyc_num
"Gets the ellipticity of the laser field."
Ellipticity(l::Cos2Laser) = l.ellip
"Gets the azimuth angle of the laser's polarization's principle axis relative to x axis (in radians)."
Azimuth(l::Cos2Laser) = l.azi
"Gets the angular frequency (ω) of the laser field (in a.u.)."
AngFreq(l::Cos2Laser) = 45.563352525 / l.wave_len
"Gets the period of the laser field (in a.u.)."
Period(l::Cos2Laser) = 2π / AngFreq(l)
"Gets the Carrier-Envelope Phase (CEP) of the laser field."
CEP(l::Cos2Laser) = l.cep
"Gets the time shift relative to the peak (in a.u.)."
TimeShift(l::Cos2Laser) = l.t_shift
"Gets the peak electric field intensity of the laser field (in a.u.)."
LaserF0(l::Cos2Laser) = sqrt(l.peak_int/(1.0+l.ellip^2)/3.50944521e16)
"Gets the peak vector potential intensity of the laser field (in a.u.)."
LaserA0(l::Cos2Laser) = LaserF0(l) / AngFreq(l)
"Gets the Keldysh parameter γ₀ of the laser field, given the ionization energy `Ip` (in a.u.)."
KeldyshParameter(l::Cos2Laser, Ip) = AngFreq(l) * sqrt(2Ip) / LaserF0(l)

"Gets the unit envelope function (the peak value is 1) of the laser field."
function UnitEnvelope(l::Cos2Laser)
    local ω = AngFreq(l); local N = CycNum(l); local Δt = l.t_shift;
    function (t)
        t -= Δt
        cos(ω*t/(2N))^2 * (abs(ω*real(t))<N*π)
    end
end

"Gets the time-dependent x component of the vector potential under dipole approximation."
function LaserAx(l::Cos2Laser)
    local A0 = LaserA0(l); local ω = AngFreq(l); local N = CycNum(l); local φ = l.cep; local Δt = l.t_shift; local ε = l.ellip; local ϕ = l.azi;
    return if ϕ==0
        function(t)
            t -= Δt
            A0 * cos(ω*t/(2N))^2 * (abs(ω*real(t))<N*π) * cos(ω*t+φ)
        end
    else
        function(t)
            t -= Δt
            A0 * cos(ω*t/(2N))^2 * (abs(ω*real(t))<N*π) * (cos(ω*t+φ)*cos(ϕ)+sin(ω*t+φ)*ε*sin(ϕ))
        end
    end
end
"Gets the time-dependent y component of the vector potential under dipole approximation."
function LaserAy(l::Cos2Laser)
    local A0 = LaserA0(l); local ω = AngFreq(l); local N = CycNum(l); local φ = l.cep; local Δt = l.t_shift; local ε = l.ellip; local ϕ = l.azi;
    return if ϕ==0
        function(t)
            t -= Δt
            A0 * cos(ω*t/(2N))^2 * (abs(ω*real(t))<N*π) * sin(ω*t+φ) * ε
        end
    else
        function(t)
            t -= Δt
            A0 * cos(ω*t/(2N))^2 * (abs(ω*real(t))<N*π) * (cos(ω*t+φ)*-sin(ϕ)+sin(ω*t+φ)*ε*cos(ϕ))
        end
    end
end
"Gets the time-dependent x component of the electric field strength under dipole approximation."
function LaserFx(l::Cos2Laser)
    local F0 = LaserF0(l); local ω = AngFreq(l); local N = CycNum(l); local φ = l.cep; local Δt = l.t_shift; local ε = l.ellip; local ϕ = l.azi;
    return if ϕ==0
        function(t)
            t -= Δt
            F0 * cos(ω*t/(2N)) * (abs(ω*real(t))<N*π) * ( cos(ω*t/(2N))*sin(ω*t+φ) + 1/N*sin(ω*t/(2N))*cos(ω*t+φ))
        end
    else
        function(t)
            t -= Δt
            F0 * cos(ω*t/(2N)) * (abs(ω*real(t))<N*π) * ( (cos(ω*t/(2N))*sin(ω*t+φ) + 1/N*sin(ω*t/(2N))*cos(ω*t+φ))*cos(ϕ) - (cos(ω*t/(2N))*cos(ω*t+φ) - 1/N*sin(ω*t/(2N))*sin(ω*t+φ))*ε*sin(ϕ) )
        end
    end
end
"Gets the time-dependent y component of the electric field strength under dipole approximation."
function LaserFy(l::Cos2Laser)
    local F0 = LaserF0(l); local ω = AngFreq(l); local N = CycNum(l); local φ = l.cep; local Δt = l.t_shift; local ε = l.ellip; local ϕ = l.azi;
    return if ϕ==0
        function(t)
            t -= Δt
            F0 * cos(ω*t/(2N)) * (abs(ω*real(t))<N*π) * ( -cos(ω*t/(2N))*cos(ω*t+φ) + 1/N*sin(ω*t/(2N))*sin(ω*t+φ)) * ε
        end
    else
        function(t)
            t -= Δt
            F0 * cos(ω*t/(2N)) * (abs(ω*real(t))<N*π) * ( (cos(ω*t/(2N))*sin(ω*t+φ) + 1/N*sin(ω*t/(2N))*cos(ω*t+φ))*-sin(ϕ) - (cos(ω*t/(2N))*cos(ω*t+φ) - 1/N*sin(ω*t/(2N))*sin(ω*t+φ))*ε*cos(ϕ) )
        end
    end
end

"Prints the information about the laser."
function Base.show(io::IO, l::Cos2Laser)
    print(io, "[MonochromaticLaser] Envelope cos², ")
    if isinteger(l.wave_len)
        @printf(io, "wavelen=%i nm, ", l.wave_len)
    else
        @printf(io, "wavelen=%.2f nm, ", l.wave_len)
    end
    if isinteger(l.cyc_num)
        @printf(io, "%i cycle(s), ", l.cyc_num)
    else
        @printf(io, "%.2f cycle(s), ", l.cyc_num)
    end
    if isinteger(l.ellip)
        @printf(io, "ε=%i", l.ellip)
    else
        @printf(io, "ε=%.2f", l.ellip)
    end
    if l.ellip == 0
        print(io, " [linearly polarized]")
    elseif abs(l.ellip) == 1
        print(io, " [circularly polarized]")
    end
    if l.t_shift != 0
        if isinteger(l.t_shift)
            @printf(io, ", peaks @ t=%i a.u.", l.t_shift)
        else
            @printf(io, ", peaks @ t=%.2f a.u.", l.t_shift)
        end
    end
    if l.cep != 0
        @printf(io, ", CEP=%.2f π", l.cep/π)
    end
    if l.azi != 0
        @printf(io, ", prin_ax_azimuth=%.2f°", l.azi/π*180)
    end
end

"Returns a `Dict{Symbol,Any}` containing properties of the object."
function Serialize(l::Cos2Laser)
    dict = OrderedDict{Symbol,Any}()
    type        = typeof(l)
    peak_int    = l.peak_int
    wave_len    = l.wave_len
    cyc_num     = l.cyc_num
    ellip       = l.ellip
    azi         = l.azi
    cep         = l.cep
    t_shift     = l.t_shift
    @pack! dict = (type, peak_int, wave_len, cyc_num, ellip, azi, cep, t_shift)
    return dict
end
