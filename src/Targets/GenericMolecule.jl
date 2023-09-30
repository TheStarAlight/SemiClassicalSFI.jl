
using .MolecularCalculators
using WignerD
using Rotations
using Dates
using HDF5

"Represents a generic molecule."
mutable struct GenericMolecule <: MoleculeBase

    "Path to the data file that stores information and data about the molecule."
    data_path::String

    "Molecular calculator that calculates energy, structure factors ... of the molecule."
    mol_calc

    #* primitive properties

    "Atoms in the molecule, stored as a vector of String."
    atoms;
    "Atoms' coordinates in the molecule, stored as a N×3 matrix."
    atom_coords;
    "Total charge of the molecule (ion)."
    charge::Integer;
    "Name of the molecule."
    name::String;

    #* properties that would be stored in data upon related calculation.

    # energy levels
    energy_data_available::Bool;
    "Energy levels of all the molecular orbitals (MO) of the molecule (in a.u.)."
    energy_levels;
    "The index of the HOMO of the molecule."
    HOMO_index;

    # WFAT IntData
    wfat_data_available::Bool;
    "Available orbital indices of WFAT IntData."
    wfat_orbital_indices::Set;
    "WFAT IntData of the molecule's molecular orbitals."
    wfat_intdata::Dict;
    "Orbital dipole moment of the molecule's molecular orbitals."
    wfat_μ::Dict;

    # Asymptotic Coeff
    asymp_coeff_available::Bool;
    "Available orbital indices of asymptotic coefficients."
    asymp_coeff_orbital_indices::Set;
    "Asymptotic coefficients of the molecule's molecular orbitals."
    asymp_coeff::Dict;

    #* properties that would not be stored in data

    "Euler angles (ZYZ convention) specifying the molecule's orientation."  # not stored in data
    rot_α;
    rot_β;
    rot_γ;


    #* fresh init without data.
    """
    Initializes a new instance of `GenericMolecule` with given parameters.
    # Parameters
    - `atoms`                   : Atoms in the molecule, stored as a vector of String.
    - `atom_coords`             : Atoms' coordinates in the molecule, stored as a N×3 matrix.
    - `charge`                  : Total charge of the molecule (ion) (optional, default 0).
    - `name`                    : Name of the molecule (optional).
    - `data_path`               : Path to the molecule's data (default empty). Specifying an empty string indicates no saving (but can still be saved later by calling method `MolSaveDataAs`).
    - `calc_energy`             : Indicates whether to calculate the energy data of the molecule upon initialization (default false).
    - `rot_α`,`rot_β`,`rot_γ`   : Euler angles (ZYZ convention) specifying the molecule's orientation (optional, default 0).
    """
    function GenericMolecule(atoms,atom_coords,charge::Integer=0,name::String="[NA]",data_path::String="",calc_energy::Bool=false,rot_α=0.,rot_β=0.,rot_γ=0.)
        @assert eltype(atoms)<:String   "[GenericMolecule] Element type of `atoms` must be String."
        @assert ndims(atom_coords)==2 && size(atom_coords,2)==3 && size(atom_coords,1)==size(atoms,1)   "[Molecule] `atom_coords` should be of size N×3."
        mol = new(  data_path,  # data_path
                    nothing,    # mol_calc
                    atoms, atom_coords, charge, name,
                    false, nothing, -1,             # energy_data
                    false, Set(), Dict(), Dict(),   # wfat_data
                    false, Set(), Dict(),           # asymp_coeff
                    rot_α,rot_β,rot_γ)
        if ! (data_path=="")
            MolSaveDataAs!(mol, data_path)
        end
        if calc_energy
            MolCalcEnergyData!(mol)
        end
        return mol
    end
    function GenericMolecule(;atoms,atom_coords,charge::Integer=0,name::String="[NA]",data_path::String="",calc_energy::Bool=false,rot_α=0.,rot_β=0.,rot_γ=0.)
        return GenericMolecule(atoms,atom_coords,charge,name,data_path,calc_energy,rot_α,rot_β,rot_γ)
    end

    #* init from data.
    function GenericMolecule(data_path::String, rot_α=0.,rot_β=0.,rot_γ=0.)
        file = h5open(data_path,"r")
        # reads MolInfo
        info_group = open_group(file, "Info")
        atoms = read_dataset(info_group, "atoms")
        atom_coords = read_dataset(info_group, "atom_coords")
        charge = read_dataset(info_group, "charge")
        name = read_dataset(info_group, "name")
        # reads MolEnergy
        energy_data_available = haskey(file, "Energy")
        energy_levels = nothing
        HOMO_index = -1
        if energy_data_available
            energy_group = open_group(file, "Energy")
            energy_levels = read_dataset(energy_group, "energy_levels")
            HOMO_index = read_dataset(energy_group, "HOMO_index")
        end
        # reads WFAT data
        wfat_data_available = haskey(file, "WFAT Data")
        wfat_orbital_indices = Set()
        wfat_intdata = Dict()
        wfat_μ = Dict()
        if wfat_data_available
            wfat_group = open_group(file, "WFAT Data")
            wfat_orbital_indices = Set(read_dataset(wfat_group, "orbital_indices"))
            for idx in wfat_orbital_indices
                wfat_intdata[idx] = read_dataset(wfat_group, "intdata_$idx")
                wfat_μ[idx] = read_dataset(wfat_group, "μ_$idx")
            end
        end
        # reads asymptotic coefficients
        asymp_coeff_available = haskey(file, "Asymptotic Coefficients")
        asymp_coeff_orbital_indices = Set()
        asymp_coeff = Dict()
        if asymp_coeff_available
            asymp_coeff_group = open_group(file, "Asymptotic Coefficients")
            asymp_coeff_orbital_indices = Set(read_dataset(asymp_coeff_group, "orbital_indices"))
            for idx in asymp_coeff_orbital_indices
                asymp_coeff[idx] = read_dataset(asymp_coeff_group, "coeff_$idx")
            end
        end

        close(file)
        return new( data_path,
                    nothing,
                    atoms, atom_coords, charge, name,
                    energy_data_available, energy_levels, HOMO_index,
                    wfat_data_available, wfat_orbital_indices, wfat_intdata, wfat_μ,
                    asymp_coeff_available, asymp_coeff_orbital_indices, asymp_coeff,
                    rot_α,rot_β,rot_γ)
    end
end


#* Molecule's specific properties & methods

"Gets the atoms in the molecule with their coordinates."
MolAtoms(mol::GenericMolecule) = mol.atoms
"Gets the atoms' coordinates in the molecule."
MolAtomCoords(mol::GenericMolecule) = mol.atom_coords
"Gets the total charge of the molecule (ion)."
MolCharge(mol::GenericMolecule) = mol.charge
"Gets the availability of the energy data of the molecule."
function MolEnergyDataAvailable(mol::GenericMolecule)
    return mol.energy_data_available
end
"Gets the energy levels of the molecule's MOs."
function MolEnergyLevels(mol::GenericMolecule)
    if ! mol.energy_data_available
        MolCalcEnergyData!(mol)
    end
    return mol.energy_levels
end
"Gets the orbital index of the molecule's HOMO."
function MolHOMOIndex(mol::GenericMolecule)
    if ! mol.energy_data_available
        MolCalcEnergyData!(mol)
    end
    return mol.HOMO_index
end
"Gets the energy of the molecule's HOMO."
function MolHOMOEnergy(mol::GenericMolecule)
    if ! mol.energy_data_available
        MolCalcEnergyData!(mol)
    end
    return mol.energy_levels[mol.HOMO_index]
end
"Gets the available orbital indices (relative to HOMO) of the molecule's WFAT data."
function MolWFATAvailableIndices(mol::GenericMolecule)
    return if mol.wfat_data_available
        mol.wfat_orbital_indices
    else
        Set()
    end
end
"""
Gets the WFAT data in format `(μ,IntData)`.
- `orbitIdx_relHOMO`: Index of selected orbit relative to the HOMO (e.g., 0 indicates HOMO, and -1 indicates HOMO-1) (default 0).
"""
function MolWFATData(mol::GenericMolecule, orbitIdx_relHOMO::Integer=0)
    if ! mol.energy_data_available
        MolCalcEnergyData!(mol)
    end
    if ! (mol.wfat_data_available || (orbitIdx_relHOMO in mol.wfat_orbital_indices))
        MolCalcWFATData!(mol, orbitIdx_relHOMO)
    end
    return mol.wfat_μ[orbitIdx_relHOMO], mol.wfat_intdata[orbitIdx_relHOMO]
end
"""
Gets the WFAT structure factor \$G_{n_ξ m}\$ according to the given Euler angles `β` and `γ` (ZYZ convention).
Note: the rotational Euler angles of the molecule would not be applied.
- `orbitIdx_relHOMO`: Index of selected orbit relative to the HOMO (e.g., 0 indicates HOMO, and -1 indicates HOMO-1) (default 0).
- `nξ`  : Parabolic quantum number nξ=0,1,2,⋯ (nξ up to 5 is calculated by default).
- `m`   : Parabolic quantum number m=⋯,-1,0,1,⋯ (|m| up to 5 is calculated by default).
- `β`   : Euler angle β, can be passed as a `Real` value or an `AbstractVector` of `Real`.
- `γ`   : Euler angle γ, can be passed as a `Real` value or an `AbstractVector` of `Real`.
"""
function MolWFATStructureFactor_G(mol::GenericMolecule, orbitIdx_relHOMO::Integer, nξ::Integer, m::Integer, β::Real, γ::Real)
    if ! mol.energy_data_available
        MolCalcEnergyData!(mol)
    end
    if ! (mol.wfat_data_available || (orbitIdx_relHOMO in mol.wfat_orbital_indices))
        MolCalcWFATData!(mol, orbitIdx_relHOMO)
    end
    @assert nξ≥0 "[GenericMolecule] nξ should be non-negative."
    intdata = mol.wfat_intdata[orbitIdx_relHOMO]
    nξMax = size(intdata,1) - 1
    mMax = round(Int,(size(intdata,2)-1)/2)
    lMax = size(intdata,3) - 1
    if nξ>nξMax
        @error "[GenericMolecule] The given nξ=$nξ is larger than the maximum value $nξMax, zero value would be returned."
        return 0.0
    end
    if abs(m)>mMax
        @error "[GenericMolecule] The given |m|=$(abs(m)) is larger than the maximum value $mMax, zero value would be returned."
        return 0.0
    end
    @inline μz(β,γ) = (RotZYZ(γ,β,0.0)*mol.wfat_μ[orbitIdx_relHOMO])[3]   # the result is independent of α

    sum = zero(ComplexF64)
    for l in abs(m):lMax, m_ in -l:l
        sum += intdata[nξ+1,m+mMax+1,l+1,m_+l+1] * WignerD.wignerdjmn(l,m,m_,β) * exp(-1im*m_*γ)
    end
    return sum * exp(-sqrt(2IonPotential(mol,orbitIdx_relHOMO))*μz(β,γ))
end
"""
Gets the WFAT structure factor \$G_{n_ξ m}\$ according to the given Euler angles `β` and `γ` (ZYZ convention).
Note: the rotational Euler angles of the molecule would not be applied.
- `orbitIdx_relHOMO`: Index of selected orbit relative to the HOMO (e.g., 0 indicates HOMO, and -1 indicates HOMO-1) (default 0).
- `nξ`  : Parabolic quantum number nξ=0,1,2,⋯ (nξ up to 5 is calculated by default).
- `m`   : Parabolic quantum number m=⋯,-1,0,1,⋯ (|m| up to 5 is calculated by default).
- `β`   : Euler angle β, can be passed as a `Real` value or an `AbstractVector` of `Real`.
- `γ`   : Euler angle γ, can be passed as a `Real` value or an `AbstractVector` of `Real`.
"""
function MolWFATStructureFactor_G(mol::GenericMolecule, orbitIdx_relHOMO::Integer, nξ::Integer, m::Integer, β::AbstractVector{T} where T<:Real, γ::AbstractVector{T} where T<:Real)
    if ! mol.energy_data_available
        MolCalcEnergyData!(mol)
    end
    if ! (mol.wfat_data_available || (orbitIdx_relHOMO in mol.wfat_orbital_indices))
        MolCalcWFATData!(mol, orbitIdx_relHOMO)
    end
    @assert size(β,1)==size(γ,1) "[GenericMolecule] Invalid input (β,γ), should be both `Real` values or two `Vector`s of `Real` and of same length."
    @assert nξ≥0 "[GenericMolecule] nξ should be non-negative."
    intdata = mol.wfat_intdata[orbitIdx_relHOMO]
    nξMax = size(intdata,1) - 1
    mMax = round(Int,(size(intdata,2)-1)/2)
    lMax = size(intdata,3) - 1
    if nξ>nξMax
        @error "[GenericMolecule] The given nξ=$nξ is larger than the maximum value $nξMax, zero value would be returned."
        return 0.0
    end
    if abs(m)>mMax
        @error "[GenericMolecule] The given |m|=$(abs(m)) is larger than the maximum value $mMax, zero value would be returned."
        return 0.0
    end
    @inline μz(β,γ) = (RotZYZ(γ,β,0.0)*mol.wfat_μ[orbitIdx_relHOMO])[3]   # the result is independent of α

    sum = zeros(ComplexF64,size(β))
    for l in abs(m):lMax, m_ in -l:l
        sum .+= intdata[nξ+1,m+mMax+1,l+1,m_+l+1] * @. WignerD.wignerdjmn(l,m,m_,β) * exp(-1im*m_*γ)
    end
    κ = sqrt(2IonPotential(mol,orbitIdx_relHOMO))
    return @. sum * exp(-κ*μz(β,γ))
end
"""
Gets the maximum value of nξ and |m| calculated in the WFAT intdata.
"""
function MolWFATMaxChannels(mol::GenericMolecule, orbitIdx_relHOMO::Integer)
    μ, intdata = MolWFATData(mol, orbitIdx_relHOMO)
    nξMax = size(intdata,1) - 1
    mMax = round(Int,(size(intdata,2)-1)/2)
    return (nξMax, mMax)
end

"Gets the available orbital indices (relative to HOMO) of the molecule's asymptotic coefficients."
function MolAsympCoeffAvailableIndices(mol::GenericMolecule)
    return if mol.asymp_coeff_available
        mol.asymp_coeff_orbital_indices
    else
        Set()
    end
end
"""
Gets the asymptotic coefficients of the molecule.
- `orbitIdx_relHOMO`: Index of selected orbit relative to the HOMO (e.g., 0 indicates HOMO, and -1 indicates HOMO-1) (default 0).
"""
function MolAsympCoeff(mol::GenericMolecule, orbitIdx_relHOMO::Integer=0)
    if ! mol.energy_data_available
        MolCalcEnergyData!(mol)
    end
    if ! (mol.asymp_coeff_available || (orbitIdx_relHOMO in mol.asymp_coeff_orbital_indices))
        MolCalcAsympCoeff!(mol, orbitIdx_relHOMO)
    end
    return mol.asymp_coeff[orbitIdx_relHOMO]
end

"""
Gets the maximum value of l calculated in the asymptotic coefficients.
"""
function MolAsympCoeff_lMax(mol::GenericMolecule, orbitIdx_relHOMO::Integer)
    return size(MolAsympCoeff(mol, orbitIdx_relHOMO), 1) - 1
end

"Gets the Euler angles (ZYZ convention) specifying the molecule's orientation in format (α,β,γ)."
MolRotation(mol::GenericMolecule) = (mol.rot_α,mol.rot_β,mol.rot_γ)
"Sets the Euler angles (ZYZ convention) specifying the molecule's orientation in format (α,β,γ)."
function SetMolRotation!(mol::GenericMolecule, α,β,γ)
    mol.rot_α = α; mol.rot_β = β; mol.rot_γ = γ;
end
function SetMolRotation!(mol::GenericMolecule, (α,β,γ))
    SetMolRotation!(mol, α,β,γ)
end
"""
Exports the given molecule's atom information to string as `MolecularCalculator`'s input.
Note: Rotations defined by the Euler angles wouldn't be applied.
"""
function MolExportAtomInfo(mol::GenericMolecule)
    atomToString(i_atm) = join([String(mol.atoms[i_atm]),mol.atom_coords[i_atm,1:3]], " ")
    return join(map(atomToString, eachindex(mol.atoms)),"; ")
end

# data calculation and operation
"""
Calculates the energy data of the molecule and saves the data.
- `MCType`      : Type of `MolecularCalculator` if it is not initialized. `PySCFMolecularCalculator` if `MC` is not specified.
- `kwargs...`   : Keyword arguments to pass to the `MolecularCalculator`, e.g. `basis`.
"""
function MolCalcEnergyData!(mol::GenericMolecule, MCType::Type = PySCFMolecularCalculator; kwargs...)
    if isnothing(mol.mol_calc)
        if ! (MCType<:MolecularCalculatorBase)
            error("[GenericMolecule] `MCType`'s type $MCType mismatches `MolecularCalculatorBase`.")
        end
        mol.mol_calc = MCType(;mol=mol, kwargs...)
    end
    mol.energy_data_available = true
    mol.energy_levels = MolecularCalculators.EnergyLevels(mol.mol_calc)
    mol.HOMO_index = MolecularCalculators.HOMOIndex(mol.mol_calc)
    _MolSaveEnergyData(mol)
end

function _MolSaveEnergyData(mol::GenericMolecule, file::HDF5.File)
    # this method will not close the file handle!
    if ! mol.energy_data_available
        return
    end
    if ! haskey(file,"Energy")
        create_group(file,"Energy")
    end
    g = open_group(file, "Energy")
    haskey(g,"energy_levels") && delete_object(g,"energy_levels")   # HDF5 doesn't support overwriting.
    haskey(g,"HOMO_index") && delete_object(g,"HOMO_index")
    write_dataset(g,"energy_levels",mol.energy_levels)
    write_dataset(g,"HOMO_index",mol.HOMO_index)
end
function _MolSaveEnergyData(mol::GenericMolecule)
    # open, write and close.
    if mol.data_path==""    # would not save if data_path is empty.
        return
    end
    if ! isfile(mol.data_path)
        error("[GenericMolecule] Destination file \"$(mol.data_path)\" does not exist.")
    end
    file = h5open(mol.data_path,"r+")
    _MolSaveEnergyData(mol,file)
    close(file)
    @info "[GenericMolecule] Energy data saved for molecule $(mol.name) at \"$(mol.data_path)\"."
end

"""
Calculates the WFAT data of the molecule and saves the data.
- `MCType`              : Type of `MolecularCalculator` if it is not initialized. `PySCFMolecularCalculator` if `MC` is not specified.
- `orbitIdx_relHOMO`    : Index of selected orbit relative to the HOMO (e.g., 0 indicates HOMO, and -1 indicates HOMO-1) (default 0).
- `kwargs...`           : Keyword arguments to pass to the `MolecularCalculator` and the `calcStructFactorData` method, e.g. `basis`, `grid_rNum`, `grid_rMax`, `sf_lMax`, ⋯
"""
function MolCalcWFATData!(mol::GenericMolecule, orbitIdx_relHOMO::Integer = 0, MCType::Type = PySCFMolecularCalculator; kwargs...)
    if isnothing(mol.mol_calc)
        if ! (MCType<:MolecularCalculatorBase)
            error("[GenericMolecule] `MCType`'s type $MCType mismatches `MolecularCalculatorBase`.")
        end
        mol.mol_calc = MCType(;mol=mol, kwargs...)
    end
    if ! mol.energy_data_available  # won't replace if the data exists.
        MolCalcEnergyData!(mol, MCType)
    end
    mol.wfat_data_available = true
    if isnothing(mol.wfat_orbital_indices)
        mol.wfat_orbital_indices = Set()
        mol.wfat_intdata = Dict()
        mol.wfat_μ = Dict()
    end
    push!(mol.wfat_orbital_indices, orbitIdx_relHOMO)
    mol.wfat_μ[orbitIdx_relHOMO], mol.wfat_intdata[orbitIdx_relHOMO] = MolecularCalculators.calc_WFAT_data(;mc=mol.mol_calc, orbitIdx_relHOMO=orbitIdx_relHOMO, kwargs...)
    _MolSaveWFATData(mol,orbitIdx_relHOMO)
end
function _MolSaveWFATData(mol::GenericMolecule, file::HDF5.File, orbitIdx_relHOMO::Integer)
    # this method will not close the file handle!
    if ! mol.wfat_data_available
        return
    end
    if ! haskey(file,"WFAT Data")
        create_group(file,"WFAT Data")
    end
    g = open_group(file, "WFAT Data")
    if ! haskey(g, "orbital_indices")
        write_dataset(g,"orbital_indices",Vector{Int32}())     # directly passing an empty array [] results in error.
    end
    indices = sort!(collect(push!(read_dataset(g,"orbital_indices"),orbitIdx_relHOMO)))
    haskey(g,"orbital_indices") && delete_object(g,"orbital_indices")   # HDF5 doesn't support overwriting.
    haskey(g,"intdata_$(orbitIdx_relHOMO)") && delete_object(g,"intdata_$(orbitIdx_relHOMO)")
    haskey(g,"μ_$(orbitIdx_relHOMO)") && delete_object(g,"μ_$(orbitIdx_relHOMO)")
    write_dataset(g,"orbital_indices", indices)
    write_dataset(g,"intdata_$(orbitIdx_relHOMO)", mol.wfat_intdata[orbitIdx_relHOMO])  # WFAT data is stored separately in different datasets!
    write_dataset(g,"μ_$(orbitIdx_relHOMO)", mol.wfat_μ[orbitIdx_relHOMO])
end
function _MolSaveWFATData(mol::GenericMolecule, orbitIdx_relHOMO::Integer)
    # open, write and close.
    if mol.data_path==""    # would not save if data_path is empty.
        return
    end
    if ! isfile(mol.data_path)
        error("[GenericMolecule] Destination file \"$(mol.data_path)\" does not exist.")
    end
    file = h5open(mol.data_path,"r+")
    _MolSaveWFATData(mol,file,orbitIdx_relHOMO)
    close(file)
    @info "[GenericMolecule] WFAT data saved for molecule $(mol.name) at \"$(mol.data_path)\"."
end
"""
Calculates the asymptotic coefficients of the molecule and saves the data.
- `MCType`              : Type of `MolecularCalculator` if it is not initialized. `PySCFMolecularCalculator` if `MC` is not specified.
- `orbitIdx_relHOMO`    : Index of selected orbit relative to the HOMO (e.g., 0 indicates HOMO, and -1 indicates HOMO-1) (default 0).
- `kwargs...`           : Keyword arguments to pass to the `MolecularCalculator`, e.g. `grid_rNum`, `l_max`.
"""
function MolCalcAsympCoeff!(mol::GenericMolecule, orbitIdx_relHOMO::Integer = 0, MCType::Type = PySCFMolecularCalculator; kwargs...)
    if isnothing(mol.mol_calc)
        if ! (MCType<:MolecularCalculatorBase)
            error("[GenericMolecule] `MCType`'s type $MCType mismatches `MolecularCalculatorBase`.")
        end
        mol.mol_calc = MCType(;mol=mol, kwargs...)
    end
    if ! mol.energy_data_available  # won't replace if the data exists.
        MolCalcEnergyData!(mol, MCType)
    end
    if isnothing(mol.asymp_coeff_available)
        mol.asymp_coeff_orbital_indices = Set()
        mol.asymp_coeff = Dict()
    end
    push!(mol.asymp_coeff_orbital_indices, orbitIdx_relHOMO)
    mol.asymp_coeff[orbitIdx_relHOMO] = MolecularCalculators.calc_asymp_coeff(; mc=mol.mol_calc, orbitIdx_relHOMO=orbitIdx_relHOMO, kwargs...)
    mol.asymp_coeff_available = true
    _MolSaveAsympCoeff(mol, orbitIdx_relHOMO)
end
function _MolSaveAsympCoeff(mol::GenericMolecule, file::HDF5.File, orbitIdx_relHOMO::Integer)
    # this method will not close the file handle!
    if ! mol.asymp_coeff_available
        return
    end
    if ! haskey(file, "Asymptotic Coefficients")
        create_group(file, "Asymptotic Coefficients")
    end
    g = open_group(file, "Asymptotic Coefficients")
    if ! haskey(g, "orbital_indices")
        write_dataset(g,"orbital_indices",Vector{Int32}())     # directly passing an empty array [] results in error.
    end
    indices = sort!(collect(push!(read_dataset(g,"orbital_indices"),orbitIdx_relHOMO)))
    haskey(g,"orbital_indices") && delete_object(g,"orbital_indices")   # HDF5 doesn't support overwriting.
    haskey(g,"coeff_$(orbitIdx_relHOMO)") && delete_object(g,"coeff_$(orbitIdx_relHOMO)")
    write_dataset(g,"orbital_indices", indices)
    write_dataset(g,"coeff_$(orbitIdx_relHOMO)", mol.asymp_coeff[orbitIdx_relHOMO])
end
function _MolSaveAsympCoeff(mol::GenericMolecule, orbitIdx_relHOMO::Integer)
    # open, write and close.
    if mol.data_path==""    # would not save if data_path is empty.
        return
    end
    if ! isfile(mol.data_path)
        error("[GenericMolecule] Destination file \"$(mol.data_path)\" does not exist.")
    end
    file = h5open(mol.data_path,"r+")
    _MolSaveAsympCoeff(mol,file,orbitIdx_relHOMO)
    close(file)
    @info "[GenericMolecule] Asymptotic coefficients of orbital index $(orbitIdx_relHOMO) saved for molecule $(mol.name) at \"$(mol.data_path)\"."
end

"Saves the data of the `GenericMolecule` to the `data_path` (will change the `Molecule`'s inner field `data_path`)."
function MolSaveDataAs!(mol::GenericMolecule, data_path::String)
    function defaultFileName()
        Y,M,D = yearmonthday(now())
        h,m,s = hour(now()), minute(now()), second(now())
        return "Molecule_$(mol.name)_$(string(Y,pad=4))$(string(M,pad=2))$(string(D,pad=2))-$(string(h,pad=2))$(string(m,pad=2))$(string(s,pad=2)).h5"
    end
    if isfile(data_path) || data_path==""        # if destination exists or not specified, saving as default file name.
        defaultPath = defaultFileName()
        if isfile(data_path)
            @warn "[GenericMolecule] Destination file \"$data_path\" already exists. Saving at \"$defaultPath\"."
        elseif data_path==""
            @warn "[GenericMolecule] Destination file not specified. Saving at \"$defaultPath\"."
        end
        data_path = defaultPath
    end
    mol.data_path = data_path
    file = h5open(data_path, "w")
    #* writes Info
    info_group = create_group(file, "Info")
    info_group["atoms"] = mol.atoms
    info_group["atom_coords"] = mol.atom_coords
    info_group["charge"] = mol.charge
    info_group["name"] = mol.name
    #* writes Energy
    if mol.energy_data_available
        _MolSaveEnergyData(mol,file)
    end
    #* writes WFAT
    if mol.wfat_data_available
        for idx in mol.wfat_orbital_indices
            _MolSaveWFATData(mol,file,idx)
        end
    end
    #* writes Asymptotic Coeff
    if mol.asymp_coeff_available
        for idx in mol.asymp_coeff_orbital_indices
            _MolSaveAsympCoeff(mol,file,idx)
        end
    end

    close(file)
    @info "[GenericMolecule] Data saved for molecule $(mol.name) at \"$(mol.data_path)\"."
end

#* Properties & methods that implement the supertype Target.

"Gets the ionization potential of the molecule's HOMO."
function IonPotential(mol::GenericMolecule)
    if ! mol.energy_data_available
        MolCalcEnergyData!(mol)
    end
    return -MolHOMOEnergy(mol)
end
"""
Gets the ionization potential of the specified MO of molecule.
- `orbitIdx_relHOMO`: Index of selected orbital relative to the HOMO (e.g., 0 indicates HOMO, and -1 indicates HOMO-1).
"""
function IonPotential(mol::GenericMolecule, orbitIdx_relHOMO::Integer)
    if ! mol.energy_data_available
        MolCalcEnergyData!(mol)
    end
    idx = mol.HOMO_index+orbitIdx_relHOMO
    if ! (0<idx<size(mol.energy_levels,1))
        error("[GenericMolecule] Orbital index out of bound.")
    end
    return -mol.energy_levels[idx]
end
"Gets the asymptotic nuclear charge of the molecule (ion) (after an electron got ionized)."
AsympNuclCharge(mol::GenericMolecule) = mol.charge + 1
"Gets the name of the molecule."
TargetName(mol::GenericMolecule) = mol.name
"Gets the ASYMPTOTIC Coulomb potential function of the molecule."
TargetPotential(mol::GenericMolecule) = (x,y,z) -> -(mol.charge+1)*(x^2+y^2+z^2+1.0)^(-0.5)
"Gets the ASYMPTOTIC Coulomb force exerted on the electron from the molecular ion (which is the neg-grad of potential)."
TargetForce(mol::GenericMolecule) = (x,y,z) -> -(mol.charge+1)*(x^2+y^2+z^2+1.0)^(-1.5) .* (x,y,z)
"Gets the trajectory function according to given parameter."
function TrajectoryFunction(mol::GenericMolecule, laserFx::Function, laserFy::Function, phase_method::Symbol, non_dipole::Bool; kwargs...)
    Z  = mol.charge+1
    Ip = IonPotential(mol)
    # including external function call is infeasible in GPU, thus the external targetF & targetP are replaced by pure Coulomb ones.
    return if ! non_dipole
        if phase_method == :CTMC
            function traj_dipole_ctmc(u,p,t)
                # tFx, tFy, tFz = targetF(u[1],u[2],u[3])
                tFx, tFy, tFz = -Z*(u[1]^2+u[2]^2+u[3]^2+1.0)^(-1.5) .* (u[1],u[2],u[3])
                du1 = u[4]
                du2 = u[5]
                du3 = u[6]
                du4 = tFx-laserFx(t)
                du5 = tFy-laserFy(t)
                du6 = tFz
                @SVector [du1,du2,du3,du4,du5,du6]
            end
        elseif phase_method == :QTMC
            function traj_dipole_qtmc(u,p,t)
                # tFx, tFy, tFz = targetF(u[1],u[2],u[3])
                tFx, tFy, tFz = -Z*(u[1]^2+u[2]^2+u[3]^2+1.0)^(-1.5) .* (u[1],u[2],u[3])
                du1 = u[4]
                du2 = u[5]
                du3 = u[6]
                du4 = tFx-laserFx(t)
                du5 = tFy-laserFy(t)
                du6 = tFz
                # du7 = -(Ip + (du1^2+du2^2+du3^2)/2 + targetP(u[1],u[2],u[3]))
                du7 = -(Ip + (du1^2+du2^2+du3^2)/2 - Z*(u[1]^2+u[2]^2+u[3]^2+1.0)^(-0.5))
                @SVector [du1,du2,du3,du4,du5,du6,du7]
            end
        elseif phase_method == :SCTS
            function traj_dipole_scts(u,p,t)
                # tFx, tFy, tFz = targetF(u[1],u[2],u[3])
                tFx, tFy, tFz = -Z*(u[1]^2+u[2]^2+u[3]^2+1.0)^(-1.5) .* (u[1],u[2],u[3])
                du1 = u[4]
                du2 = u[5]
                du3 = u[6]
                du4 = tFx-laserFx(t)
                du5 = tFy-laserFy(t)
                du6 = tFz
                # du7 = -(Ip + (du1^2+du2^2+du3^2)/2 + targetP(u[1],u[2],u[3]) + (u[1]*tFx+u[2]*tFy+u[3]*tFz))
                du7 = -(Ip + (du1^2+du2^2+du3^2)/2 - Z*(u[1]^2+u[2]^2+u[3]^2+1.0)^(-0.5) + (u[1]*tFx+u[2]*tFy+u[3]*tFz))
                @SVector [du1,du2,du3,du4,du5,du6,du7]
            end
        end
    else
        if phase_method == :CTMC
            function traj_nondipole_ctmc(u,p,t)
                # tFx, tFy, tFz = targetF(u[1],u[2],u[3])
                tFx, tFy, tFz = -Z*(u[1]^2+u[2]^2+u[3]^2+1.0)^(-1.5) .* (u[1],u[2],u[3])
                c0 = 137.035999173
                du1 = u[4] + u[3]*laserFx(t)/c0
                du2 = u[5] + u[3]*laserFy(t)/c0
                du3 = u[6]
                du4 = tFx - laserFx(t)
                du5 = tFy - laserFy(t)
                du6 = tFz - (u[4]*laserFx(t)+u[5]*laserFy(t))/c0
                @SVector [du1,du2,du3,du4,du5,du6]
            end
        else
            #TODO: QTMC & SCTS.
        end
    end
end

using Printf
function Base.show(io::IO, mol::GenericMolecule)
    @printf(io, "[GenericMolecule] %s", mol.name)
    if mol.energy_data_available
        @printf(io, ", HOMO_energy=%.4f", MolHOMOEnergy(mol))
    end
    print(io,"\n")
end

using Parameters, OrderedCollections
"Returns a `Dict{Symbol,Any}` containing properties of the object."
function Serialize(t::GenericMolecule)
    dict = OrderedDict{Symbol,Any}()
    type        = typeof(t)
    data_path   = t.data_path
    atoms       = t.atoms
    atom_coords = t.atom_coords
    charge      = t.charge
    name        = t.name
    rot_alp     = t.rot_α
    rot_bet     = t.rot_β
    rot_gam     = t.rot_γ
    @pack! dict = (type, data_path, atoms, atom_coords, charge, name, rot_alp, rot_bet, rot_gam)
    return dict
end