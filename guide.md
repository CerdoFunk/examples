#Brief Guide
Here are some notes to assist in running the programs.

##Data Input
Most of the Fortran codes use a `namelist` to input a few parameters from standard input.
This gives an easy way to specify default values in the program itself, and to use a
keyword-based syntax to specify values different from the default ones at run-time.
The input file, or string, should usually begin with `&nml` and end with `/`.
As a minimum, the program will expect to read `&nml /` (an empty list), but to
change the parameters, typical input might be
```
&nml nblock=20, nstep=1000, dt=0.001 /
```
and the `key=value` pairs may be set out on different lines if you wish.

##Initial Configuration
Simulation runs require a starting configuration which can usually be prepared using
the `initialize` program (in `build_initialize/`).
The default parameters produce an FCC configuration of 256 atoms at reduced density &rho; = 0.75,
writing out just the positions (for an MC program) to a file `cnf.inp`.
If the parameter `velocities=.true.` is supplied, then positions and velocities are
written to the file, corresponding to a reduced temperature _T_ = 1.0.
These values of &rho; and _T_ (see below) lie in the liquid region of the Lennard-Jones phase diagram.
Non-default values may, of course, be preferable for this or other models.
The `cnf.inp` file may then be copied to the directory in which the run is carried out.
Typically, runs produce a final configuration `cnf.out`
(which may be renamed to `cnf.inp` as a starting point for further runs)
and intermediate configurations `cnf.001`, `cnf.002` etc during the run.

##State points for different Lennard-Jones models
For most of the examples, we use a cutoff of _Rc_ = 2.5 &sigma;.
For MC programs the cut (but not shifted) potential (c) is used in the simulation,
while for MD programs the cut-and-shifted potential (cs) is used.
In all cases, an attempt is made to produce results without, and with, long-range corrections,
the latter giving an estimate for the full potential (f).
Differences between the different models are discussed in various places,
see e.g.

* A Trokhymchuk, J Alejandre, _J Chem Phys,_ __111,__ 8510 (1999).

Using their table V as a guide, we take the critical point to be roughly located at:

LJ model                 | _T_ | &rho; | _P_
-----                    | ---- | ---- | ----
f: full, with LRC        | 1.31 | 0.31 | 0.13
c: cut (but not shifted) | 1.19 | 0.32 | 0.11
cs: cut-and-shifted      | 1.08 | 0.32 | 0.09

At any temperature below _Tc_, the liquid state is bounded below by the
liquid-gas coexistence density, and using Tables II-IV of the same reference as a guide,
we take the values for three example temperatures as

LJ model                 |  _T_ | &rho; | _P_
-----                    | ---- |  ---- | ----
f: full, with LRC        |  0.8 | 0.793 | 0.005
c: cut (but not shifted) |  0.8 | 0.765 | 0.008
cs: cut-and-shifted      |  0.8 | 0.730 | 0.013

LJ model                 |  _T_ | &rho; | _P_
-----                    | ---- |  ---- | ----
f: full, with LRC        |  0.9 | 0.746 | 0.012
c: cut (but not shifted) |  0.9 | 0.714 | 0.020
cs: cut-and-shifted      |  0.9 | 0.665 | 0.030

LJ model                 |  _T_ | &rho; | _P_
-----                    | ---- |  ---- | ----
f: full, with LRC        |  1.0 | 0.695 | 0.026
c: cut (but not shifted) |  1.0 | 0.652 | 0.036
cs: cut-and-shifted      |  1.0 | 0.578 | 0.062

For Lennard-Jones, the default state point (&rho; = 0.75 and _T_ =1.0)
lies in the liquid region of the phase diagram for all these variants of the model.

For comparison with MD runs, a wide range of simulation data for LJ with
_Rc_ = 2.5  &sigma; (cut-and-shifted, denoted cs below) is summarized by

* M Thol, G Rutkai, R Span, J Vrabec and R Lustig, _Int J Thermophys,_ __36,__ 25 (2015)

who present data (in Supplementary Information) and a fitted approximate
equation of state (which they also provide as a C++ program).

Approximate equations of state for the full LJ potential are available from

* J Kolafa and I Nezbeda, _Fluid Phase Equil,_ __100,__ 1 (1994)
* M Mecke, A Muller, J Winkelmann, J Vrabec, J Fischer, R Span, W Wagner,
_Int J Thermophys,_ __17,__ 391 (1996) and __19,__ 1493(E) (1998)

Below we use the Kolafa & Nezbeda formulae (denoted f) and estimate the results
for the cut-but-not-shifted potential (denoted c) using the same corrections as in the MC codes.
The formulae are implemented in the supplied program `eos_lj`.

Here we compare with typical test runs from our programs using default parameters except where stated.
Note that E/N is the total internal energy per atom, including the ideal gas part.

Source           | &rho;   | _T_         | _E/N_ (cs) | _P_ (cs) | _E/N_ (c) | _P_ (c) | _E/N_ (f) | _P_ (f) |
------           | ------- | ----------- | --------   | ------   | -------   | ------  | --------  | ------- |
Thol et al       |   0.75  |   1.00      | -2.9280    | 0.9909   |           |         |           |         |
Kolafa & Nezbeda |   0.75  |   1.00      |            |          | -3.3172   | 0.6951  | -3.7188   | 0.3939  |
`bd_nvt_lj`      |   0.75  |   1.00      | -2.93(1)   | 0.98(2)  |           |         | -3.73(1)  | 0.38(2) |

#Brownian dynamics program
The program `bd_nvt_lj` carries out a Brownian dynamics simulation for a set of atoms
interacting through the cut-and-shifted Lennard-Jones potential.
An initial configuration may be prepared, at a typical Lennard-Jones state point,
using the `initialize` program in the usual way.
As well as the usual run parameters, similar to a molecular dynamics code,
the user specifies a friction coefficient.
The calculated average thermodynamic quantities should be as expected for an
equilibrium simulation of this model at the chosen state point (see e.g. the table above).

#Cluster program
The `cluster` program is self contained. It reads in a configuration of atomic positions
and produces a circular linked list for each cluster identified within it.
The best value of the critical separation `r_cl` depends on the particular physical system
being considered. The supplied default will, for a liquid-state Lennard-Jones configuration,
most likely identify almost all atoms as belonging to a single cluster, with at most
a few atoms being isolated on their own. However, this is unlikely to be the type of system
for which this analysis is useful.

#Correlation function program
The aim of the program `corfun` is to illustrate the direct method, and the FFT method,
for calculating time correlation functions.
The program is self contained: it generates the time dependent data itself,
using a generalized Langevin equation,
for which the time correlation function is known.
The default parameters produce a damped, oscillatory, correlation function,
but these can be adjusted to give monotonic decay,
or to make the oscillations more prominent.
If the `origin_interval` parameter is left at its default value of 1,
then the direct and FFT methods should agree with each other to within numerical precision.
The efficiency of the direct method may be improved,
by selecting origins less frequently,
and in this case the results obtained by the two methods may differ a little.

#Diffusion program
The program `diffusion` reads in a sequence of configurations and calculates
the velocity auto correlation function, the mean square displacement, and
the cross-correlation between velocity and displacement.
Any of these may be used to estimate the diffusion coefficient,
as described in the text.
The output appears in `diffusion.out`
It is instructive to plot all three curves vs time.

The input trajectory is handled in a crude way,
by reading in successive snapshots with filenames `cnf.000`, `cnf.001`, etc.
These might be produced by a molecular dynamics program,
at the end of each block,
choosing to make the blocks fairly small (perhaps 10 steps).
As written, the program will only handle up to `cnf.999`.
Obviously, in a practical application,
a proper trajectory file would be used instead of these separate files.

It is up to the user to provide the time interval between successive configurations.
This will typically be a small multiple of the timestep used in the original simulation.
This value `delta` is only used to calculate the time, in the first column of
the output file.
A default value of 1 is provided as a place-holder, but
the user really should specify a physically meaningful value;
forgetting to do so could cause confusion when one attempts
to quantify the results.

To make it easier to test this program,
we have also supplied a self-contained program `diffusion_test`,
which generates an appropriate trajectory by numerically solving
the simple Langevin equation for N non-interacting atoms.
For this model, one specifies the temperature and friction coefficient,
which dictates the rate of exponential decay of the vacf,
and hence the diffusion coefficient.

#DPD program
For the `dpd` example, we recommend generating an initial configuration
using the `initialize` program (in `build_initialize/`), with the
following namelist input
```
&nml n = 100, density = 3.0, random_positions = .true., velocities = .true. /
```
The value of the density is typical when using this method to model water.
The approximate DPD equation of state is used to estimate the pressure,
at the chosen density, temperature, and interaction strength, for comparison.
This is expected to become inaccurate for densities lower than about 2.