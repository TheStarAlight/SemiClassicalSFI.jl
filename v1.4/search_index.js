var documenterSearchIndex = {"docs":
[{"location":"theory_initial_conditions/#Initial-Conditions","page":"Initial Conditions","title":"Initial Conditions","text":"","category":"section"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"This section reviews commonly-used theories used to provide initial conditions in the trajectory simulations.","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"A number of theories can be adapted to provide initial conditions of the classical electrons in the trajectory simulation scheme. The initial condition usually consists of three properties:","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"Initial position bmr_0 (i.e., the tunneling exit position);\nInitial momentum bmp_0, we note that in the trajectory simulation schemes, initial momentum are usually denoted using bmk_0;\nThe corresponding ionization probability W carried by each electron sample, depending on the time-dependent laser field and the properties of the target atoms/molecules.","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"In the following we will give a brief review on the available theories we implemented in SemiclassicalSFI.jl. Atomic units (a.u.) are used throughout unless stated otherwise.","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"Pages = [\"theory_initial_conditions.md\"]","category":"page"},{"location":"theory_initial_conditions/#Strong-Field-Approximation-(SFA)","page":"Initial Conditions","title":"Strong-Field Approximation (SFA)","text":"","category":"section"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"The Strong-Field Approximation (SFA) is originated from the Keldysh theory of strong-field ionization. Compared with the pertubative methods and adiabatic tunneling theories, the SFA is able to predict both the multi-photon and the tunneling process during the laser-atom interaction, as well as high-order non-pertubative phenomenona such as the above-threshold ionization (ATI) because it fully includes the non-adiabatic effect of the laser-atom interaction. The broad scope of SFA has contributed to its widespread application in theoretical investigations of strong-field ionization.","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"Considering the electron evolving under a combined field of the Coulomb field V(bmr) and the laser field bmF(t)=-partial_t bmA(t), under the length gauge (LG), its Hamiltonian reads","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"H = frac12 bmp^2 + V(bmr) + bmF(t)cdotbmr","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"Denoting ketPsi_0 = ketpsi_0 mathrme^mathrmiI_mathrmpt as the unperturbed initial state with ionization potential of I_mathrmp, ketPsi_bmp as the continuum state of momentum bmp, and","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"U(t_mathrmft_mathrmi) = exp left -mathrmi int_t_mathrmi^t_mathrmf H(tau) mathrmdtau right","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"the time-evolution operator, the transition amplitude between the initial state and the final state of momentum bmp is written as","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"M_bmp = braket Psi_bmp  U(t_mathrmft_mathrmi)  Psi_0 ","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"Here lies the key idea of SFA: when the influence of the Coulomb field to the ionized electrons is weak compared with that of the external laser field, we may neglect the influence of the Coulomb field in the expression of M_bmp by replacing the time-evolution operator with a Coulomb-free one U_mathrmf, and meanwhile replacing the continuum state with the Volkov state ketPsi^mathrmV_bmp which represents a free electron evolving under the same laser field:","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"M_bmp = braket Psi^mathrmV_bmp  U_mathrmf(t_mathrmft_mathrmi)  Psi_0 ","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"where the Volkov state under the LG is the product of a plane wave and a phase factor:","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"ket Psi^mathrmV_bmp  = ket bmp+bmA(t)  mathrme^-mathrmiS_bmp(t)","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"and the phase has the expression:","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"S_bmp(t) = int^t frac12 bmp+bmA(tau)^2 mathrmdtau","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"In this way the M_bmp is expressed as","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"M_bmp = -mathrmi int_t_mathrmi^t_mathrmf braket bmp+bmA(tau)  bmF(tau)cdotbmr  psi_0  mathrme^mathrmitildeS_bmp(tau) mathrmdtau","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"and we note that here we have extracted the phase factor of ketPsi_0 and combined it with the former mathrme^mathrmiS_bmp(t), giving","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"tildeS_bmp(t) = int^t left frac12 bmp+bmA(tau)^2 + I_mathrmp right mathrmdtau","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"Utilizing the saddle-point approximation (SPA) would give a more consise expression of M_bmp. The variation of tildeS_bmp(t) is much more sensitive than that of braket bmp+bmA(t)  bmF(t)cdotbmr  psi_0  as t varies, which leads to a fact that the whole integrand in our latest expression of M_bmp oscillates in its complex phase and its values cancel out each other in most cases, except when the variation of the phase tildeS_bmp(t) becomes stable, i.e., at the saddle points of tildeS_bmp(t). The saddle points t_mathrms=t_mathrmr+mathrmit_mathrmi are the zeroes of the derivative of the complex function tildeS_bmp(t), which satisfy","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"partial_t tildeS_bmp(t) _t=t_mathrms = frac12 bmp+bmA(t_mathrms)^2 + I_mathrmp = 0","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"The integral can be approximated by a summation over the saddle points:","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"M_bmp approx sum_t_mathrms P_bmp(t_mathrms) mathrme^mathrmitildeS_bmp(t_mathrms)","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"where P_bmp(t_mathrms) denotes the prefactor. Here we use a modified version of SFA which takes account of the Coulomb potential, which gives the prefactor","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"P_bmp(t_mathrms) =  bmp+bmA(t_mathrms) cdot bmF(t_mathrms) ^-alpha2","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"where alpha = 1+Zsqrt2I_mathrmp. The phase tildeS_bmp(t_mathrms) is obtained by solving the integral","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"beginaligned\n    tildeS_bmp(t_mathrms)\n    = int_-infty^t_mathrms left frac12 bmp+bmA(tau)^2 + I_mathrmp right mathrmdtau \n    = left( -int_t_mathrms^t_mathrmr -int_t_mathrmr^infty right) left frac12 bmp+bmA(tau)^2 + I_mathrmp right mathrmdtau \n    = Phi_mathrmtun + Phi_mathrmtraj\nendaligned","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"where Phi_mathrmtun represents the complex phase accumulation during the tunneling process, whose real part denotes the quantum phase, while its imaginary part, is related to the ionization probability; the Phi_mathrmtraj, is the phase accumulation during the electron trajectory motion in the continuum.","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"The SFA provides the final momentum distribution, while the trajectory simulation requires initial conditions of the eletrons. To utilize the SFA to give initial conditions, we suppose that the classical electron is ejected at time t_mathrmr at tunneling exit bmr_0 with momentum bmk_0. The initial momentum bmk_0, neglecting the Coulomb potential, is related to the final momentum bmp through","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"bmp = bmk_0 + int_t_mathrmr^infty bmF(tau) mathrmdtau = bmk_0 - bmA(t_mathrmr)","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"The initial position bmr_0, i.e., the tunneling exit, is found by constructing a quantum tunneling trajectory. The beginning of the trajectory, i.e., the tunneling entrance, has a real part of zero; the electron tunnels through the barrier during the time interval t_mathrms to t_mathrmr and emerges as a classical electron at the tunneling exit with real position and momentum. In this way we obtain the expression of the initial position:","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"bmr_0 = mathrmRe int_t_mathrms^t_mathrmr bmA(tau) mathrmdtau = mathrmIm int_0^t_mathrmi bmA(t_mathrmr+mathrmitau) mathrmdtau","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"The probablity density (in the final momentum space) carried by the electron sample is","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"mathrmdWmathrmdbmp = lvert P_bmp(t_mathrms) rvert^2 exp(-2 mathrmIm Phi_mathrmtun)","category":"page"},{"location":"theory_initial_conditions/#SFA-with-Adiabatic-Expansion-(SFA-AE)","page":"Initial Conditions","title":"SFA with Adiabatic Expansion (SFA-AE)","text":"","category":"section"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"For small Keldysh parameter gamma, the non-adiabatic effect is not significant, thus an adiabatic expansion scheme can be carried out to develop a modified theory based on the SFA, which is named after the SFA with adiabatic expansion (SFA-AE). It partially includes the non-adiabatic effect and is competent to give similar results compared with that given by the SFA under small Keldysh parameters.","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"The SFA-AE is applicable when the Keldysh parameter is small or the non-adiabatic effect is insignificant, and we recall that in the SFA there is a corresponding quantity t_mathrmi which quantifies the non-adiabacity of tunneling. For small t_mathrmi, we expand the vector potential bmA(t_mathrmr + mathrmit_mathrmi) at t_mathrmr, up to the second order of t_mathrmi:","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"bmA(t_mathrmr + mathrmit_mathrmi) = bmA(t_mathrmr) - mathrmit_mathrmibmF(t_mathrmr) + frac12 t_mathrmi^2 bmF(t_mathrmr) + o(t_mathrmi^2)","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"Inserting the above expression into the saddle-point equation in the SFA gives","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"bmk(t_mathrmr) cdot bmF(t_mathrmr) = 0","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"and","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"t_mathrmi = sqrtfrack^2(t_mathrmr)+2I_mathrmpF^2(t_mathrmr)-bmk(t_mathrmr) cdot bmF(t_mathrmr)","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"The mathrmIm Phi_mathrmtun related to the ionization rate, in the SFA-AE, is","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"mathrmIm Phi_mathrmtun approx -frac13 sqrtfrack^2(t_mathrmr)+2I_mathrmp^3F^2(t_mathrmr)-bmk(t_mathrmr) cdot bmF(t_mathrmr)","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"and we obtain","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"beginaligned\n    mathrmdWmathrmdbmp\n    = lvert P_bmp(t_mathrms) rvert^2 exp(-2 mathrmIm Phi_mathrmtun) \n    = lvert P_bmp(t_mathrms) rvert^2 exp left -frac23 sqrtfrack_perp^2+2I_mathrmp^3F^2-bmk_perp cdot bmF right\nendaligned","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"where the bmk_perp denotes the transverse momentum at the tunneling exit, which is actually equivalent to bmk(t_mathrmr) in the SFA-AE because the above saddle-point equation requires bmk(t_mathrmr) cdot bmF(t_mathrmr) = 0. We note that the initial momentum, bmk_0, is exactly bmk_perp.","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"The initial position has the expression","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"bmr_0 = mathrmIm int_0^t_mathrmi bmA(t_mathrmr+mathrmitau) mathrmdtau = fracbmF2 frack_perp^2+2I_mathrmpF^2-bmk_perp cdot bmF","category":"page"},{"location":"theory_initial_conditions/#Ammosov-Delone-Krainov-(ADK)","page":"Initial Conditions","title":"Ammosov-Delone-Krainov (ADK)","text":"","category":"section"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"The Ammosov-Delone-Krainov (ADK) theory is used to study the adiabatic tunneling in the strong-field ionization, and is, in a sense, the adiabatic limit of the SFA.","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"In the adiabatic limit, the laser field can be treated as static, thus we have bmF(t)=bm0 (higher order derivatives of bmF(t) remains zero as well). Substuting it into the expressions of SFA-AE yields the ADK rate","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"mathrmdWmathrmdbmp = lvert P_bmp(t_mathrms) rvert^2 exp left -frac23 frack_perp^2+2I_mathrmp^32F right","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"and the tunneling exit position","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"bmr_0 = mathrmIm int_0^t_mathrmi bmA(t_mathrmr+mathrmitau) mathrmdtau = fracbmF2 frack_perp^2+2I_mathrmpF^2","category":"page"},{"location":"theory_initial_conditions/#Molecular-ADK-(MO-ADK)","page":"Initial Conditions","title":"Molecular ADK (MO-ADK)","text":"","category":"section"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"The molecular ADK (MO-ADK) theory generalizes the original ADK theory by extending the application scope from atomic to simple linear molecules.","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"In the MO-ADK theory, the wavefunction of a linear molecule's ionizing orbital behaves asymptotically as","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"psi_0^(m)(bmr) sim sum_l C_l F_l(r) Y_lm(thetaphi)","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"in the molecular frame (MF) when rrightarrowinfty, where m denotes the magnetic quantum number along the molecular axis (m=012 denotes sigmapi and delta symmetries respectively). Assigning kappa=sqrt2I_mathrmp, the F_l(r) has the following asymptotic behavior when rrightarrowinfty:","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"F_l(r) sim r^Zkappa-1 mathrme^-kappa r","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"We assume the electric field is pointing towards the z axis in the laboratory frame (LF). The angle-dependent tunneling ionization rate in the MO-ADK theory reads","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"Gamma(betagamma) = mathrmdWmathrmdt = sum_m fracB_m(betagamma)^22^mm kappa^-m left(frac2kappa^2Fright)^2Zkappa-m-1 mathrme^-2kappa^33F","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"where the molecule's orientation is described using a set of Euler angles hatbmR = (alphabetagamma) (z-y-z convention), which represents the rotational transformation from the MF to the LF; B_m(betagamma) are the structural parameters which depend on the molecule's orbital wavefunction (here we omitted the alpha dependence because the structural parameters are independent of alpha). The structural parameters B_m(betagamma) have the following expression:","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"B_m(betagamma) = C_l d_m m^l(beta) mathrme^-mathrmimgamma Q_l m","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"with d_m m^l(beta) being the Wigner-d rotation matrix, and","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"Q_l m = (-1)^m sqrtfrac(2l+1)(l+m)2(l-m)","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"To ultilize the MO-ADK theory to provide the initial conditions in the trajectory simulation, we simply adopt the result of the atomic ADK theory:","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"bmr_0 = fracbmF2 frack_perp^2+2I_mathrmpF^2","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"As for the ionization probability, we include the influence of the initial kinetic energy k_perp^22 by replacing the kappa=sqrt2I_mathrmp with kappa(k_perp)=sqrt2I_mathrmp+k_perp^2 in the exponential term of the ionization probability in the MO-ADK theory, giving","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"mathrmdWmathrmdbmk_perp mathrmdt = sum_m fracB_m(betagamma)^22^mm kappa^-m left(frac2kappa^2Fright)^2Zkappa-m-1 mathrme^-2kappa^3(k_perp)3F","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"[[[Question: The normalization coefficient?]]]","category":"page"},{"location":"theory_initial_conditions/#Weak-Field-Asymptotic-Theory-(WFAT)","page":"Initial Conditions","title":"Weak-Field Asymptotic Theory (WFAT)","text":"","category":"section"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"The weak-field asymptotic theory (WFAT) generalizes the tunneling ionization from isotropic atomic potentials to arbitrary molecular potentials. Compared with the MO-ADK theory, the WFAT accounts for the influence of the molecules' permanent dipole moment, and is applicable for complex molecules other than simple linear molecules.","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"The formulation of the WFAT is based on the expansion in the parabolic coordinates. The total ionization rate Gamma(betagamma) = mathrmdWmathrmdt, is split into different parabolic channels:","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"Gamma(betagamma) = sum_nu Gamma_nu(betagamma)","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"where Gamma_nu(betagamma) are partial rates of parabolic quantum number indices nu=(n_xim), and n_xi=012cdots, m=0pm 1pm 2cdots. In the leading-order approximation of the WFAT, the partial rates can be separated into two factors, namely the structural part G_nu(betagamma)^2 and the field part W_nu(F):","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"Gamma_nu(betagamma) = G_nu(betagamma)^2 W_nu(F)","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"The field factor is expressed as","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"W_nu(F) = frackappa2 left(frac4kappa^2Fright)^2Zkappa-2n_xi-m-1 mathrme^-2kappa^33F","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"The structure factor, in the integral representation of the WFAT, is given as an integral:","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"G_nu (betagamma) = mathrme^-kappamu_z int Omega_nu^* left(hatbmR^-1 bmrright) hatV_mathrmc(bmr) psi_0(bmr) mathrmd bmr","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"where psi_0 is the wavefunction of the ionizing orbital,","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"bmmu = int psi_0^*(bmr) bmr psi_0(bmr) mathrmd bmr","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"denotes the orbital dipole moment in the LF, with mu_z being its component along the field direction;","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"Omega_nu(bmr) = sum_l=m^infty Omega^nu_lm(bmr) = sum_l=m^infty R_l^nu(r) Y_lm(theta phi)","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"is a reference function which can be expanded into spherical harmonics, its radial part is expressed as","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"R_l^nu(r)=omega_l^nu  (kappa r)^l  mathrme^-kappa r  mathrmM(l+1-Zkappa 2l+2 2 kappa r)","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"with mathrmM(abx) being the confluent hyper-geometric function and","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"beginaligned\n    omega_l^nu =        (-1)^l+(m-m)2+1 2^l+32 kappa^Zkappa-(m+1)2-n_xi \n                    times sqrt(2l+1)(l+m)(l-m)(m+n_xi)n_xi fracl(2l+1) \n                    times  sum_k=0^min(n_xil-m)  fracGamma(l+1-Zkappa+n_xi-k)k(l-k)(m+k)(l-m-k)(n_xi-k)\nendaligned","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"the normalization coefficient; hatV_mathrmc(bmr)=hatV(bmr)+Zr is the core potential with the Coulomb tail removed, where Z is the asymptotic charge of the residual ion.","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"The effective potential hatV(bmr) describes the interaction between the ionizing electron and the residual parent ion. Under the framework of the Hartree-Fock method, the effective potential consists of three parts, namely the nuclear Coulomb potential (V_mathrmnuc), the direct (V_mathrmd) and exchange (V_mathrmex) parts of inter-electron interactions:","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"hatV(bmr) = V_mathrmnuc(bmr) + V_mathrmd(bmr) + hatV_mathrmex(bmr)","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"and","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"beginaligned\n    V_mathrmnuc(bmr) = -sum_A=1^N_mathrmatm fracZ_Aleftbmr-bmR_Aright \n    V_mathrmd(bmr) = sum_i=1^N int fracpsi_i^*(bmr) psi_i(bmr)bmr-bmr mathrmd bmr \n    hatV_mathrmex(bmr) psi_0(bmr) = -sum_i=1^N psi_i(bmr) int fracpsi_i^*(bmr) psi_0(bmr)bmr-bmr braketsigma_i  sigma_0 mathrmd bmr\nendaligned","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"where N is the number of electrons, N_mathrmatm is the number of nuclei, psi_i(bmr) and sigma_i denote the molecular orbital and the spin state of the electron of index i (braketsigma_isigma_j=1 if electrons of index i and j have the same spin, and braketsigma_isigma_j=0 otherwise), Z_A and bmR_A are the nuclear charge and position of atom of index A.","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"As the WFAT provides only the ionization rate Gamma = mathrmdWmathrmdt as the MO-ADK does, we adopt the same procedure as we did in the MO-ADK theory to provide the initial conditions for the trajectory simulation. The initial position bmr_0 is the same as that in the MO-ADK theory, and the ionization rate reads","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"mathrmdWmathrmdbmk_perp mathrmdt = sum_nu G_nu(betagamma)^2 cdot frackappa2 left(frac4kappa^2Fright)^2Zkappa-2n_xi-m-1 mathrme^-2kappa^3(k_perp)3F","category":"page"},{"location":"theory_initial_conditions/","page":"Initial Conditions","title":"Initial Conditions","text":"[[[Question: The normalization coefficient?]]]","category":"page"},{"location":"#SemiclassicalSFI.jl","page":"Home","title":"🎆SemiclassicalSFI.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Implementation of classical/semiclassical methods in strong-field ionization of atoms and molecules.","category":"page"},{"location":"#Background","page":"Home","title":"Background","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The interaction between laser and matter has attracted widespread interest since the invention of laser technology decades ago. To study the interaction between an ultrafast and intense laser pulse and atoms/molecules, where the electrons are ionized from the targets through multi-photon or tunneling/over-barrier processes, a time-dependent Schrödinger equation (TDSE) simulation is usually required to be carried out. However, its high demand in computational resources and limited application scope (atoms and simple molecules) prevents it from its extensive application.","category":"page"},{"location":"","page":"Home","title":"Home","text":"To overcome the shortcomings of TDSE, Corkum et al. [Corkum_1989] proposed a scheme, where the electron is first ionized from the target through the tunneling mechanism, and then acts as a classical electron in the laser field. This scheme was further developed by Hu et al. [Hu_1997], in which the initial conditions of the classical electrons and the Coulomb potential of the parent ion are more appropriatedly taken account. This scheme is named after the Classical Trajectory Monte-Carlo (CTMC) method, which has been widely adopted for research in interaction between high-intensity ultra-fast laser pulses and atoms/molecules. Compared with TDSE, trajectory simulation schemes including CTMC and its variants, are less demanding in computational resources, which, in addition, provides a clear physical picture of strong-field ionization.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The essence of the trajectory simulation scheme lies in two aspects: (1) The initial conditions of the classical electron samples at the beginning of the classical trajectories, which consists of initial position bmr_0 (i.e., the tunneling exit position), initial momenta bmp_0, and the corresponding ionization probability W carried by the electron sample. (2) The quantum phase property of classical trajectories, while the full classical trajectory (i.e., the CTMC) is widely adopted, there are schemes (e.g., QTMC and SCTS, which would be discussed further in the documentation) which introduce quantum phases in the electron trajectories and develop a semiclassical method for trajectory simulations.","category":"page"},{"location":"","page":"Home","title":"Home","text":"After decades of accumulation of research and development, the trajectory simulation has grown to a complete solution of research on strong-field ionization of atoms and molecules. Developing a library with implementation of existing methods, efficiency of calculation, extensibility for future development and ease of maintenance would provide great convenience for theoretical research on strong-field ionization. With such aim, here we present SemiclassicalSFI.jl, a program package written in julia language, which provides a general, efficient and out-of-box solution of performing trajectory simulations.","category":"page"},{"location":"","page":"Home","title":"Home","text":"[Corkum_1989]: Corkum, P. B. et al. Above-Threshold Ionization in the Long-Wavelength Limit. Phys. Rev. Lett. 62(11), 1259–1262 (1989). DOI: 10.1103/PhysRevLett.62.1259","category":"page"},{"location":"","page":"Home","title":"Home","text":"[Hu_1997]: Hu, B. et al. Plateau in Above-Threshold-Ionization Spectra and Chaotic Behavior in Rescattering Processes. Phys. Lett. A 236(5–6), 533–542 (1997). DOI: 10.1016/S0375-9601(97)00811-6","category":"page"},{"location":"#Features","page":"Home","title":"Features","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Versatile :     SemiclassicalSFI.jl supports a wide range of functions. As for initial conditions (rate method), the library supports (for atoms) ADK, SFA and SFA-AE, (for molecules) MOADK and WFAT. As for the trajectory phase method, the library supports CTMC, QTMC and SCTS. Non-dipole effects can also be included during the trajectory simulation.\nOut-of-box :    The usage of SemiclassicalSFI.jl is simple and straightforward.\nExtensible :    SemiclassicalSFI.jl has a well-defined structure, which makes it easy to include new features.","category":"page"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"#Prerequisites","page":"Home","title":"Prerequisites","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Minimum prerequisites : Julia ≥1.7\nGPU acceleration of traj. simulation : a supported graphic card (NVIDIA is suggested)\nMOADK and WFAT features : Linux or MacOS platform, Python 3 with the pyscf python package installed and the PyCall.jl package successfully built.","category":"page"},{"location":"#Installing-the-package","page":"Home","title":"Installing the package","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This package is currently not in julia's general registry, but can be added through the repository URL:","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Pkg\nPkg.add(url=\"https://github.com/TheStarAlight/SemiclassicalSFI.jl.git\")\n# In pkg mode of REPL:\n# (@v1.8) pkg> add https://github.com/TheStarAlight/SemiclassicalSFI.jl.git","category":"page"},{"location":"","page":"Home","title":"Home","text":"It is suggested to test the package to check if the functions of the package run properly:","category":"page"},{"location":"","page":"Home","title":"Home","text":"Pkg.test(\"SemiclassicalSFI\")\n# In pkg mode of REPL:\n# (@v1.8) pkg> test SemiclassicalSFI","category":"page"},{"location":"","page":"Home","title":"Home","text":"note: Possible solution to precompilation failure\nSometimes the precompilation of the package and its dependencies fails, which usually happens on SciML's packages. Under such circumstances, try to delete the compiled julia code (usually stored in ~/.julia/compiled/<julia_version>) and precompile again. If the problem still exists after precompiling from scratch, you may try switching the SciML dependencies' versions in the julia, which is done by specifying the version when adding the packages:using Pkg\nPkg.add(name=\"package_name\", version=\"1.0\")\n# In pkg mode of REPL:\n# (@v1.8) pkg> add package_name@1.0It is shown that OrdinaryDiffEq@6.51 and DiffEqGPU@1.26 runs well on Windows 10 and Manjaro Linux.","category":"page"},{"location":"#Configuring-Python-and-pyscf","page":"Home","title":"Configuring Python and pyscf","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Currently the MOADK and WFAT features related to molecules rely on the pyscf python package, which doesn't support Windows platform. SemiclassicalSFI.jl calls the pyscf using the PyCall.jl package. There are two ways to set up the Python environment used by PyCall, here we suggest using your local Python environment for convenience.","category":"page"},{"location":"","page":"Home","title":"Home","text":"To correctly set up the configuration of PyCall, first, set the PYTHON environment variable to your Python executable, and build the PyCall package:","category":"page"},{"location":"","page":"Home","title":"Home","text":"ENV[\"PYTHON\"] = \"path/to/python_exec\"\nusing Pkg\nPkg.build(\"PyCall\")","category":"page"},{"location":"","page":"Home","title":"Home","text":"And don't forget to install pyscf in your Python via pip:","category":"page"},{"location":"","page":"Home","title":"Home","text":"$ pip3 install pyscf","category":"page"},{"location":"#Contributors","page":"Home","title":"Contributors","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Mingyu Zhu @ ECNU\nHongcheng Ni @ ECNU","category":"page"},{"location":"#License","page":"Home","title":"License","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This package is licensed under the Apache 2.0 license, and is copyrighted by Mingyu Zhu, Hongcheng Ni and the other contributors.","category":"page"}]
}
