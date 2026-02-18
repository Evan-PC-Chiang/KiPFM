# **KiPFM**

[![DOI](https://zenodo.org/badge/1073194793.svg)](https://doi.org/10.5281/zenodo.18663840)


Matlab codes implementing a **Kinematic Plate-based Fault Model (KiPFM)** to reconcile geological (uplift/incision) and geodetic (GPS, leveling) rates, estimating **fault slip rates** and **locking distributions** within a two-layer lithosphere framework.

## Overview

- **Goal**: Reconcile short-term geodetic deformation with long-term geological rates to infer spatially variable **slip rates** and **locking** on specified faults.
- **Approach**: The model treats the lithosphere as an **elastic plate** with an embedded **3D fault surface** overlying an **inviscid substrate**. An **MCMC inversion** is used to estimate **strike-slip**, **dip-slip**, and the **locking distribution**.
- **Output**: 
  - Slip rates
  - Locking areas
  - Predicted velocity fields
  - Residuals and uncertainty

## Features

- Combine **GPS velocities and leveling** with **geological uplift/incision rates** in one model.
- Supports **multi-fault**, **multi-segment** parameterizations; far field plate-rate and/or detachment-based boundary conditions.
- Flexible **weighting schemes** for balancing datasets and improving regularization.
- Ability to reproduce and compare against a **grid-based velocity field**.

---

# Result Overview

Please visit [here](https://evan-pc-chiang.github.io/3D_Taiwan_model/) for more details.

---

# Code Overview

```plain text
Main Folder
├── mesh
│   ├── example.m                      % Example file
│   ├── traces                         % Fault traces in WGS84 [lat long]
│   ├── fault_mesh_files               % Output file for Kplate
│   ├── data                           % Data for plotting
│   └── tools                          % Tool box
└── Kplate
    ├── run_example
    │   ├── codes                      % Template folder for inversion
    │   │   ├── P01_setup_Kplate.m     - Set up and visualize the plate geometry
    │   │   ├── P02_Make_Green.m       - Build Green’s functions for the inversion
    │   │   ├── P03_Do_MCMC.m          - Run the MCMC inversion
    │   │   ├── R01_std_calculator.m   - Compute standard deviations and summary statistics
    │   │   ├── R02_plot_single.m      - Plot contributions from individual faults
    │   │   └── R03_to_json.m          - Export inversion results to JSON format
    │   ├── data                       % Data for inversion
    │   │   ├── coast_file.txt
    │   │   ├── data_set.txt
    │   │   ├── load_bounds.m
    │   │   └── name_full.m
    │   ├── fault_mesh_files           % Output file from mesh
    │   └── result
    └── tools                          % Tool box
        └── codes for inversion and plotting
```

## Work Flow

> We provides rum_example as a test file which has the same setup with the paper for you to reproduce the results. This is already optimized the MCMC therefore it burn-in in a decent rate. If you encounter a difficulty of burn-in, please check the weighting factors and/or step size.

1. Build fault mesh files in mesh folder. View example.m to see how to execute these code.
2. Sepecify loading fault by creating a txt file under `/fault_mesh_files` named FaultName_rec.txt as follow:

```plain text
Start_local_lon Start_local_lat End_local_lon End_local_lat Dipping_angle
```

3. Copy the `/fault_mesh_files` into the `/run_example` folder.
4. Modify `data/Fault_name_list.m` to specify the geometry you want to use.
5. Create a file called `data_set.txt` with the following format. Use **type = 1** for short-term geodetic rates (e.g., GPS, leveling) and **type = 2** for long-term geological rates. **NOTE: MUST list all short-term before long-term**

```plain text
% type   lon       lat      E        N        U        E.sig   N.sig   U.sig
1        121.1383  22.7793  -65.1310 18.5580  -2.8680  0.9930  0.8350  1.2340   % GPS
1        120.4340  23.5582   NaN     NaN      -3.5678   NaN     NaN    0.3510   % Leveling
...
2        120.1178  23.1021   NaN     NaN      -3.4000   NaN     NaN    0.3000   % Geological rate
```

6. Specify input details in `P01_setup_Kplate.m`. Check the fault geometry and data locations.
7. Specify node variance under `Setup Slip nodes` section in `P02_Make_Green.m`.
8. Specify `load_bounds.m`. Code would automatically assign upper and lower. **NOTE: NOTATION MATTERS**.
9. Specify weighting under `Change weighting` in `P03_Do_MCMC.m`.  Use anything learn in inversion that works on sigma.
10. Let cook until **Burn-In** and wait for a while or till `numsteps` has done.
11. Check the results by `R01_std_calculator`
    1. Or see single fault or multiple fault contribution by `R02_plot_single.m`
    2. Or output to json file by `R03_to_json` 

## Data Structure for GF.mat

```
faults
├── fault_names
│   ├── meshtype         % 'tri' for mesh fault, 'rec' for loading fault
│   ├── trinode          % Nodes for triangular mesh
│   ├── tri              % Indices of triangles
│   ├── pm               % Patch model, blank when meshtype = 'tri'
│   ├── bounds           % Boundaries on the fault
│   │   ├── ss           % [upper, lower] 
│   │   ├── ds           % [upper, lower]
│   │   ├── lowerLd      % km, double
│   │   └── UpperLd      % km, double
│   ├── Greens           % Original greens function
│   │   ├── ss           % Both in e, n, u 
│   │   │   ├── elastic
│   │   │   └── viscoelastic
│   │   └── ds           % Both in e, n, u
│   │       ├── elastic
│   │       └── viscoelastic
│   ├── G_mcmc           % Matrix for inversion purpose
│   ├── results
│   │   ├── ds           % Dip-slip on each mesh
│   │   ├── ss           % Strike-slip on each mesh
│   │   ├── lowerLd      % km, double
│   │   └── UpperLd      % km, double
│   ├── patch_stuff      % Details for each tri-face
│   ├── nodes            % Details for along-strike variables
│   └── contribution     % Contributions from this fault
├── fault_names
├── fault_names
└── fault_names
data
xy_coast
origin
```

The original **Green’s functions** are stored in faults.fault_name.Greens, where the three components (E, N, U) are separated into **strike-slip**, **dip-slip**, **elastic**, and **viscoelastic** contributions.

G_mcmc combines these terms by direction for each slip component.

## Advanced Usage

The results for each direction (**E**, **N**, **U**) are the sum of strike-slip and dip-slip contributions. The inverted observation points are defined by your data_set.txt. Therefore, you can:

- Generate a **grid-based solution** if data_set.txt is arranged on a grid.
- Extract the contributions from **strike-slip** or **dip-slip**, and from **elastic** or **viscoelastic** components.
- Apply a **dense dataset** (e.g., InSAR) by adjusting the Green’s functions accordingly.

---

# References

Meade, B. J. (2007), Algorithms for the calculation of exact displacements, strains, and stresses for triangular dislocation elements in a uniform elastic half space, *Comput. Geosci.*, 33, 1064–1075.

<div style="text-align: right"> <a href="https://doi.org/10.1016/j.cageo.2006.12.003">Artical</a> <a href="https://scholar.google.com/citations?view_op=view_citation&hl=en&user=Lw4pPtUAAAAJ&citation_for_view=Lw4pPtUAAAAJ:zYLM7Y9cAGgC">Google Scholar</a> </div>

---

Johnson, K. M., Hammond, W. C., Burgette, R. J., Marshall, S. T., & Sorlien, C. C. (2020). Present-day and long-term uplift across the western transverse ranges of southern California. *Journal of Geophysical Research: Solid Earth*, 125(8), e2020JB019672. https://doi.org/10.1029/2020JB019672.

<div style="text-align: right"> <a href="https://doi.org/10.1029/2020JB019672">Artical</a> <a href="https://scholar.google.com/citations?view_op=view_citation&hl=en&user=564iLhYAAAAJ&cstart=20&pagesize=80&citation_for_view=564iLhYAAAAJ:K3LRdlH-MEoC">Google Scholar</a> </div>
