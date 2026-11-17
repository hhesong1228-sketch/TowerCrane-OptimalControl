# Model validation figures — captions and notes

Each figure is available as a 300 dpi PNG, a vector PDF, and an editable MATLAB FIG. The combined PDF is `Model_Validation_Figures_EN.pdf`.

This updated English edition includes 3-, 6-, 9-, and 12-element meshes. The 12-element mesh is a numerical reference, not an analytical or experimental truth.

**Figure 1. Cantilever static verification.** (a) Numerical tip deflection versus the analytical solution for a cantilever subjected to a transverse tip load. (b) Relative analytical errors in tip deflection and rotation versus the number of retained beam modes. The relative error is |numerical/analytical − 1| × 100%. This benchmark verifies the isolated jib submodel, rather than the full coupled tower–jib static response.

**Figure 2. Fixed-suspension, fixed-length pendulum frequency comparison.** Lowest linearized natural angular frequencies for the original elastic-cable parameters and a near-ideal pendulum parameter set, compared with √(g/L). The two suspension-point position degrees of freedom are fixed, while cable slope degrees of freedom remain free. The near-ideal case is sensitive to finite-difference linearization; its small mesh-dependent changes should not be interpreted as physical convergence. Frequencies are obtained from a linearized eigenvalue problem, not from free-swing time histories.

**Figure 3. ALE fixed-domain limit check.** Norm of the ALE additional inertial force for fixed and moving material-domain test cases. Nonzero nodal velocities are used in both cases. The ALE contribution vanishes when the cable-length rate and acceleration are both zero. The moving-domain value is a nonzero control, not the peak force from a full simulation. Units: mN.

**Figure 4. ANCF mesh comparison of payload trajectories.** Upper panels: horizontal and vertical payload positions for the completed 3-, 6-, 9-, and 12-element meshes. Lower panels: signed position differences relative to the 12-element mesh, in μm. The vertical coordinate is positive downward. The tower and jib each retain four modes; prescribed motions, output times, and integration settings are common to all meshes.

**Figure 5. ANCF mesh comparison of cable-end axial forces.** Upper panel: lower-end constitutive axial force EA(|r_s| − 1). Lower panel: signed differences relative to the 12-element mesh, in mN. Constitutive axial force is distinct from total end traction, which can include bending contributions.

**Figure 6. Differences between adjacent ANCF meshes.** (a) Maximum Euclidean distance between payload positions for each adjacent mesh pair. (b) Maximum absolute axial-force difference, normalized by the peak absolute axial force of the finer mesh and expressed as a percentage. Both vertical axes are logarithmic. Connecting lines guide the eye and do not represent a fitted convergence order.

## Interpretation limits

The figures support implementation verification and mesh stability for the tested case. They do not establish experimental accuracy, parameter calibration, or convergence with respect to the retained beam modes. The completed 12-element temporal-refinement check gives a maximum payload-position difference of approximately 5.59e-12 m after tightening integration settings. This is below the 9-to-12-element position difference of 5.07e-9 m. This temporal check concerns payload position; no equivalent axial-force temporal error is supplied here. Strictly monotonic error reduction is not required near the numerical precision limit.

Exact adjacent-mesh metrics are supplied in `plotted_mesh_metrics.csv`; scope is recorded in `figure_scope.txt`. Reproduce this edition from the repository root with `addpath('matlab'); setup_paths; plot_model_limits_en`.
