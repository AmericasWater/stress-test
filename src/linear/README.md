# stress-test

Full county stress-test example of the America's Water model, using linear
programming.

## Installation

0. Install Julia v0.4:

   Go to the [Julia download page](http://julialang.org/downloads/).

1. Clone this repository:
   ```
   git clone https://github.com/AmericasWater/stress-test.git
   ```

2. Install Gurobi:

   Go to the [Gurobi download page](http://www.gurobi.com/academia/for-universities).

   You will also need to go through the license creation process.

3. Install the development version of OptiMimi:

   Start Julia, and then call:
   ```
   Pkg.clone("https://github.com/jrising/OptiMimi.jl.git")
   ```
   Then close Julia.

4. Navigate a shell to the `src/linear` directory and run `main.jl`.

   ```
   cd src/linear
   julia main.jl
   ```

*Notes:*

The code comes with networks for the whole US and just for Colorado.  If you
need other states, contain James for the neighboring county network.

It will then take a long time to generate the constraint matrix.  One of the
next tasks is to save this matrix after it's been generated.
