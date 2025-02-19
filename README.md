mcbrnet: an R package for simulating metacommunity dynamics in a
branching network
================
Akira Terui
May 07, 2021

-   [Overview](#overview)
-   [Installation](#installation)
-   [Instruction](#instruction)
    -   [`brnet()`](#brnet)
        -   [Basic usage](#basic-usage)
        -   [Quick start](#quick-start)
        -   [Custom setting:
            visualization](#custom-setting-visualization)
        -   [Custom setting: environment](#custom-setting-environment)
        -   [Custom setting: disturbance](#custom-setting-disturbance)
        -   [Custom setting: asymmetric distance
            matrix](#custom-setting-asymmetric-distance-matrix)
    -   [`mcsim()`](#mcsim)
        -   [Basic usage](#basic-usage-1)
        -   [Quick start](#quick-start-1)
        -   [Custom setting: combine `brnet()` and
            `mcsim()`](#custom-setting-combine-brnet-and-mcsim)
        -   [Custom setting: detailed
            parameters](#custom-setting-detailed-parameters)
        -   [Model description](#model-description)
    -   [`adjtodist`](#adjtodist)
        -   [Basic usage](#basic-usage-2)
-   [References](#references)

# Overview

The package `mcbrnet` is composed of two functions: `brnet()` and
`mcsim()`.

-   `brnet`: Function `brnet()` generates a random branching network
    with the specified number of patches and probability of branching.
    The function returns adjacency and distance matrices, hypothetical
    environmental values at each patch, and the number of patches
    upstream (akin to the watershed area in river networks). The output
    may be used in function `mcsim()` to simulate metacommunity dynamics
    in a branching network.

-   `mcsim`: Function `mcsim()` simulates metacommunity dynamics. By
    default, it produces a square-shaped landscape with randomly
    distributed habitat patches (x- and y-coordinates are drawn from a
    uniform distribution). If a distance matrix is given, the function
    simulates metacommunity dynamics in the specified landscape.
    Function `mcsim()` follows a general framework proposed by Thompson
    et al. (2020). However, it has several unique features that are
    detailed in the following sections.

# Installation

The `mcbrnet` package can be installed with the following script:

``` r
#install.packages("remotes")
remotes::install_github("aterui/mcbrnet")
library(mcbrnet)
```

# Instruction

## `brnet()`

### Basic usage

The key arguments are the number of habitat patches (`n_patch`) and the
probability of branching (`p_branch`), which users must specify. With
these parameters, the function generates a branching network through the
following steps:

1.  Draw the number of branches in the network. An individual branch is
    defined as a series of connected patches from one confluence (or
    outlet) to the next confluence upstream (or upstream terminal). The
    number of branches in a network BR is drawn from a binomial
    distribution as BR \~ Binomial(N, P<sub>br</sub>), where N is the
    number of patches and P<sub>br</sub> is the branching probability.

2.  Draw the number of patches in each branch. The number of patches in
    each branch N<sub>br</sub> is drawn from a geometric distribution as
    N<sub>br</sub> \~ Ge(P<sub>br</sub>) but conditional on
    ΣN<sub>br</sub> = N.

3.  Organize branches into a bifurcating branching network.

Sample script:

``` r
net <- brnet(n_patch = 50, p_branch = 0.5)
```

The function returns:

-   `adjacency_matrix`: adjacency matrix.

-   `distance_matrix`: distance matrix. Distance between patches is
    measured as the number of steps required to reach from the focal
    patch to the target patch through the network.

-   `weighted_distance_matrix`: weighted distance matrix. Upstream steps
    may be weighted (see **Custom setting**).

-   `df_patch`: a data frame (`dplyr::tibble`) containing patch
    attributes.

    -   *patch\_id*: patch ID.
    -   *branch\_id*: branch ID.
    -   *environment*: environmental value at each patch (see below for
        details)
    -   *disturbance*: disturbance level (i.e., proportional mortality)
        at each patch (see below for details)
    -   *n\_patch\_upstream*: the number of upstream contributing
        patches (including the focal patch itself; akin to the watershed
        area in river networks).

### Quick start

The following script produce a branching network with `n_patch = 50` and
`p_branch = 0.5`. By default, `brnet()` visualizes the generated network
using functions in packages `igraph` (Csardi and Nepusz 2006) and
`plotfunctions` (van Rij 2020) (`plot = FALSE` to disable):

``` r
net <- brnet(n_patch = 50, p_branch = 0.5)
```

![](README_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

Randomly generated environmental values color patches and patches’ size
is proportional to the number of patches upstream. To view matrices,
type the following script:

``` r
# adjacency matrix
# showing 10 patches for example
net$adjacency_matrix[1:10, 1:10]
```

    ##         patch1 patch2 patch3 patch4 patch5 patch6 patch7 patch8 patch9 patch10
    ## patch1       0      0      0      0      0      0      0      0      0       0
    ## patch2       0      0      0      0      0      0      0      0      0       0
    ## patch3       0      0      0      1      0      0      0      0      0       0
    ## patch4       0      0      1      0      0      0      0      0      0       0
    ## patch5       0      0      0      0      0      0      0      0      0       0
    ## patch6       0      0      0      0      0      0      1      0      0       0
    ## patch7       0      0      0      0      0      1      0      0      0       0
    ## patch8       0      0      0      0      0      0      0      0      1       0
    ## patch9       0      0      0      0      0      0      0      1      0       1
    ## patch10      0      0      0      0      0      0      0      0      1       0

``` r
# distance matrix
# showing 10 patches for example
net$distance_matrix[1:10, 1:10]
```

    ##         patch1 patch2 patch3 patch4 patch5 patch6 patch7 patch8 patch9 patch10
    ## patch1       0      9      3      4      3     12     13      9     10      11
    ## patch2       9      0     12     13     12      3      4      2      3       4
    ## patch3       3     12      0      1      2     15     16     12     13      14
    ## patch4       4     13      1      0      3     16     17     13     14      15
    ## patch5       3     12      2      3      0     15     16     12     13      14
    ## patch6      12      3     15     16     15      0      1      5      6       7
    ## patch7      13      4     16     17     16      1      0      6      7       8
    ## patch8       9      2     12     13     12      5      6      0      1       2
    ## patch9      10      3     13     14     13      6      7      1      0       1
    ## patch10     11      4     14     15     14      7      8      2      1       0

The following script lets you view branch ID, environmental values, and
the number of upstream contributing patches for each patch:

``` r
net$df_patch
```

    ## # A tibble: 50 x 5
    ##    patch_id branch_id environment disturbance n_patch_upstream
    ##       <int>     <dbl>       <dbl>       <dbl>            <dbl>
    ##  1        1         1      -1.33        0.899               50
    ##  2        2         8      -0.693       0.899                9
    ##  3        3         6      -1.96        0.895                6
    ##  4        4         6      -1.93        0.895                5
    ##  5        5        23      -0.145       0.898                1
    ##  6        6        21       0.872       0.889                2
    ##  7        7        21       0.804       0.889                1
    ##  8        8        13      -0.890       0.889                5
    ##  9        9        13      -0.938       0.889                4
    ## 10       10        13      -0.967       0.889                3
    ## # ... with 40 more rows

### Custom setting: visualization

Arguments: `patch_label`, `patch_scaling`, `patch_size`

Users may add patch labels using the argument `patch_label`:

``` r
# patch ID
net <- brnet(n_patch = 50, p_branch = 0.5, patch_label = "patch")
```

![](README_files/figure-gfm/unnamed-chunk-9-1.png)<!-- -->

``` r
# branch ID
net <- brnet(n_patch = 50, p_branch = 0.5, patch_label = "branch")
```

![](README_files/figure-gfm/unnamed-chunk-11-1.png)<!-- -->

``` r
# number of upstream contributing patches
net <- brnet(n_patch = 50, p_branch = 0.5, patch_label = "n_upstream")
```

![](README_files/figure-gfm/unnamed-chunk-13-1.png)<!-- -->

To remove patch size variation, set `patch_scaling = FALSE` and specify
`patch_size`:

``` r
# number of upstream contributing patches
net <- brnet(n_patch = 50, p_branch = 0.5, patch_scaling = FALSE, patch_size = 8)
```

![](README_files/figure-gfm/unnamed-chunk-15-1.png)<!-- -->

### Custom setting: environment

Arguments: `mean_env_source`, `sd_env_source`, `rho`, `sd_env_lon`

Some flexibility exists to simulate environmental values, which are
determined through an autoregressive process, as detailed below:

1.  Environmental values for upstream terminal patches (i.e., patches
    with no upstream patch) are drawn from a normal distribution as
    z<sub>1</sub> \~ Normal(μ<sub>source</sub>,
    σ<sub>source</sub><sup>2</sup>) (arguments `mean_env_source` and
    `sd_env_source`).

2.  Downstream environmental values are determined by an autoregressive
    process as z<sub>x</sub> = ρz<sub>x-1</sub> + ε<sub>x</sub> (‘x-1’
    means one patch upstream), where ε<sub>x</sub> \~ Normal(0,
    σ<sup>2</sup><sub>env</sub>) (argument `sd_env_lon`). At bifurcation
    patches (or confluence), the environmental value takes a weighted
    mean of the two contributing patches given the size of these patches
    *s* (the number of upstream contributing patches): z<sub>x</sub> =
    ω(ρz<sub>1,x-1</sub> + ε<sub>1,x</sub>) + (1 -
    ω)(ρz<sub>2,x-1</sub> + ε<sub>2,x</sub>), where ω =
    s<sub>1</sub>/(s<sub>1</sub> + s<sub>2</sub>).

Users may change the values of μ<sub>source</sub> (default:
`mean_env_source = 0`), σ<sub>source</sub> (`sd_env_source = 1`), ρ
(`rho = 1`), and σ<sub>env</sub> (`sd_env_lon = 0.1`). Increasing the
value of `sd_env_source` leads to greater variation in environmental
values at upstream terminals. The argument `rho` (0 ≤ ρ ≤ 1) determines
the strength of longitudinal autocorrelation (the greater the stronger
autocorrelation). The argument `sd_env_lon` (σ<sub>env</sub> &gt; 0)
determines the strength of longitudinal environmental noise. The
following script produces a network with greater environmental variation
at upstream terminals (z<sub>1</sub> \~ Normal(0, 3<sup>2</sup>)),
weaker longitudinal autocorrelation (ρ = 0.5), and stronger local noises
(σ<sub>env</sub> = 0.5).

``` r
net <- brnet(n_patch = 50, p_branch = 0.5,
             sd_env_source = 3, rho = 0.5, sd_env_lon = 0.5)
```

![](README_files/figure-gfm/brnet_instruction_2-1.png)<!-- -->

### Custom setting: disturbance

Arguments: `mean_disturb_source`, `sd_disturb_source`

Some flexibility exists to simulate disturbance levels, as detailed
below:

1.  Disturbance levels for upstream terminal patches (i.e., patches with
    no upstream patch) are drawn from a normal distribution as
    m<sub>1</sub> \~ Normal(μ<sub>m</sub>, σ<sub>m</sub><sup>2</sup>).
    The argument `mean_disturb_source` controls the proportional mean of
    the disturbance level, which will be converted to a logit-scale
    value in the function (i.e., μ<sub>m</sub> =
    logit(`mean_disturb_source`)). The argument `sd_disturb_source`
    controls the variation in disturbance level among headwaters in a
    logit scale (i.e., σ<sub>m</sub> = `sd_disturb_source`)

2.  Downstream disturbance levels are identical to the adjacent upstream
    patch except at confluences. At bifurcation patches (or confluence),
    the disturbance value takes a weighted mean of the two contributing
    patches given the size of these patches *s* (the number of upstream
    contributing patches): m<sub>x</sub> = ωm<sub>1,x-1</sub> + (1 -
    ω)m<sub>2,x-1</sub>, where ω = s<sub>1</sub>/(s<sub>1</sub> +
    s<sub>2</sub>).

3.  The logit-scale values will be back-transformed to the proportional
    values (return value = inv.logit(m))

Users may change the values of μ<sub>m</sub> (default:
`mean_disturb_source = 0.9`) and σ<sub>m</sub> (`sd_env_source = 0.1`).

### Custom setting: asymmetric distance matrix

Arguments: `asymmetry_factor`

Distance between patches is calculated as the number of steps from the
origin to the target patch. Specifically, distance from patch x to y,
d<sub>xy</sub>, is calculated as:

d<sub>xy</sub> = step<sub>d</sub> + δstep<sub>u</sub>

where step<sub>d</sub> the number of downstream steps, step<sub>u</sub>
the number of upstream steps, and δ the asymmetry scaling factor
(`asymmetry_factor`). Users may change δ to control the weight of
upstream steps. (1) δ = 1, upstream and dowstream steps have no
difference (default), (2) δ &gt; 1, upstream steps have greater costs,
(3) δ &lt; 1, downstream steps have greater costs. Changes to
`asymmetry_factor` will be reflected in `weighted_distance_matrix`.

## `mcsim()`

### Basic usage

The key arguments are the number of habitat patches (`n_patch`) and the
number of species in a metacommunity (`n_species`). The metacommunity
dynamics are simulated through (1) local dynamics (population growth and
competition among species), (2) immigration, and (3) emigration.

Sample script:

``` r
mc <- mcsim(n_patch = 5, n_species = 5)
```

The function returns:

-   `df_dynamics` a data frame containing simulated metacommunity
    dynamics\*.

    -   *timestep*: time-step.
    -   *patch\_id*: patch ID.
    -   *mean\_env*: mean environmental condition at each patch.
    -   *env*: environmental condition at patch x and time-step t.
    -   *carrying\_capacity*: carrying capacity at each patch.
    -   *species*: species ID.
    -   *niche\_optim*: optimal environmental value for species i.
    -   *r\_xt*: reproductive number of species i at patch x and
        time-step t.
    -   *abundance*: abundance of species i at patch x.

-   `df_species` a data frame containing species attributes.

    -   *species*: species ID.
    -   *mean\_abundance*: mean abundance (arithmetic) of species i
        across sites and time-steps.
    -   *r0*: maximum reproductive number of species i.
    -   *niche\_optim*: optimal environmental value for species i.
    -   *sd\_niche\_width*: niche width for species i.
    -   *p\_dispersal*: dispersal probability of species i.

-   `df_patch` a data frame containing patch attributes.

    -   *patch*: patch ID.
    -   *alpha\_div*: alpha diversity averaged across time-steps.
    -   *mean\_env*: mean environmental condition at each patch.
    -   *carrying\_capacity*: carrying capacity at each patch.
    -   *connectivity*: structural connectivity at each patch. See below
        for details.

-   `df_diversity` a data frame containing diversity metrics (α, β, and
    γ).

-   `distance_matrix` a distance matrix used in the simulation.

-   `interaction_matrix` a species interaction matrix, in which species
    X (column) influences species Y (row).

\*NOTE: The warm-up and burn-in periods will not be included in return
values.

### Quick start

The following script simulates metacommunity dynamics with `n_patch = 5`
and `n_species = 5`. By default, `mcsim()` simulates metacommunity
dynamics with 200 warm-up (initialization with species introductions:
`n_warmup`), 200 burn-in (burn-in period with no species introductions:
`n_burnin`), and 1000 time-steps for records (`n_timestep`).

``` r
mc <- mcsim(n_patch = 5, n_species = 5)
```

Users can visualize the simulated dynamics using `plot = TRUE`, which
will show five sample patches and species that are randomly chosen:

``` r
mc <- mcsim(n_patch = 5, n_species = 5, plot = TRUE)
```

![](README_files/figure-gfm/unnamed-chunk-19-1.png)<!-- -->

A named list of return values:

``` r
mc
```

    ## $df_dynamics
    ## # A tibble: 25,000 x 9
    ##    timestep patch_id mean_env     env carrying_capaci~ species niche_optim  r_xt
    ##       <dbl>    <dbl>    <dbl>   <dbl>            <dbl>   <dbl>       <dbl> <dbl>
    ##  1        1        1        0 -0.0494              100       1      -0.968  1.43
    ##  2        1        1        0 -0.0494              100       2       0.291  2.79
    ##  3        1        1        0 -0.0494              100       3      -0.562  1.29
    ##  4        1        1        0 -0.0494              100       4      -0.311  3.07
    ##  5        1        1        0 -0.0494              100       5       0.108  2.83
    ##  6        1        2        0 -0.0142              100       1      -0.968  1.35
    ##  7        1        2        0 -0.0142              100       2       0.291  2.85
    ##  8        1        2        0 -0.0142              100       3      -0.562  1.11
    ##  9        1        2        0 -0.0142              100       4      -0.311  2.97
    ## 10        1        2        0 -0.0142              100       5       0.108  2.86
    ## # ... with 24,990 more rows, and 1 more variable: abundance <dbl>
    ## 
    ## $df_species
    ## # A tibble: 5 x 6
    ##   species mean_abundance    r0 niche_optim sd_niche_width p_dispersal
    ##     <dbl>          <dbl> <dbl>       <dbl>          <dbl>       <dbl>
    ## 1       1           5.44     4      -0.968          0.752         0.1
    ## 2       2          61.0      4       0.291          0.696         0.1
    ## 3       3           0        4      -0.562          0.351         0.1
    ## 4       4          62.3      4      -0.311          0.536         0.1
    ## 5       5          60.6      4       0.108          0.807         0.1
    ## 
    ## $df_patch
    ## # A tibble: 5 x 5
    ##   patch_id alpha_div mean_env carrying_capacity connectivity
    ##      <dbl>     <dbl>    <dbl>             <dbl>        <dbl>
    ## 1        1      3.80        0               100       0.307 
    ## 2        2      3.57        0               100       0.0674
    ## 3        3      3.68        0               100       0.0971
    ## 4        4      3.5         0               100       0.0388
    ## 5        5      3.81        0               100       0.281 
    ## 
    ## $df_diversity
    ## # A tibble: 1 x 3
    ##   alpha_div beta_div gamma_div
    ##       <dbl>    <dbl>     <dbl>
    ## 1      3.67     1.04      3.81
    ## 
    ## $df_xy_coord
    ## # A tibble: 5 x 2
    ##   x_coord y_coord
    ##     <dbl>   <dbl>
    ## 1    5.10   4.46 
    ## 2    5.69   0.185
    ## 3    3.59   6.52 
    ## 4    9.60   1.11 
    ## 5    6.30   3.48 
    ## 
    ## $distance_matrix
    ##          patch1   patch2   patch3   patch4   patch5
    ## patch1 0.000000 4.318499 2.546035 5.621133 1.550521
    ## patch2 4.318499 0.000000 6.670318 4.025012 3.352600
    ## patch3 2.546035 6.670318 0.000000 8.088696 4.065424
    ## patch4 5.621133 4.025012 8.088696 0.000000 4.072806
    ## patch5 1.550521 3.352600 4.065424 4.072806 0.000000
    ## 
    ## $weighted_distance_matrix
    ## NULL
    ## 
    ## $interaction_matrix
    ##     sp1 sp2 sp3 sp4 sp5
    ## sp1   1   0   0   0   0
    ## sp2   0   1   0   0   0
    ## sp3   0   0   1   0   0
    ## sp4   0   0   0   1   0
    ## sp5   0   0   0   0   1

### Custom setting: combine `brnet()` and `mcsim()`

Return values of `brnet()` are compatible with `mcsim()`. For example,
`df_patch$environment`, `df_patch$n_patch_upstream`, and
`df_patch$distance_matrix` may be used to inform parameters of
`mcsim()`:

``` r
patch <- 100
net <- brnet(n_patch = patch, p_branch = 0.5, plot = F)
mc <- mcsim(n_patch = patch, n_species = 5,
            mean_env = net$df_patch$environment,
            carrying_capacity = net$df_patch$n_patch_upstream*10,
            distance_matrix = net$distance_matrix,
            plot = T)
```

![](README_files/figure-gfm/unnamed-chunk-21-1.png)<!-- -->

### Custom setting: detailed parameters

Users may use the following arguments to custom metacommunity
simulations regarding (1) species attributes, (2) competition, (3) patch
attributes, and (4) landscape structure.

#### Species attributes

Arguments: `r0`, `niche_optim` OR `min_optim` and `max_optim`,
`sd_niche_width` OR `min_niche_width` and `max_niche_width`,
`niche_cost`, `p_dispersal`

Species attributes are determined based on the maximum reproductive rate
`r0`, optimal environmental value `niche_optim` (or `min_optim` and
`max_optim` for random generation of `niche_optim`), niche width
`sd_niche_width` (or `min_niche_width` and `max_niche_width` for random
generation of `sd_niche_width`) and dispersal probability `p_dispersal`
(see **Model description** for details).

For optimal environmental values (niche optimum), the function by
default assigns random values to species as: μ<sub>i</sub> \~
Uniform(min<sub>μ</sub>, max<sub>μ</sub>), where users can set values of
min<sub>μ</sub> and max<sub>μ</sub> using `min_optim` and `max_optim`
arguments (default: `min_optim = -1` and `max_optim = 1`).
Alternatively, users may specify species niche optimums using the
argument `niche_optim` (scalar or vector). If a single value or a vector
of `niche_optim` is provided, the function ignores `min_optim` and
`max_optim` arguments.

Similarly, the function by default assigns random values of
σ<sub>niche</sub> to species as: σ<sub>niche,i</sub> \~
Uniform(min<sub>σ</sub>, max<sub>σ</sub>), where users can set values of
min<sub>σ</sub> and max<sub>σ</sub> using `min_niche_width` and
`max_niche_width` arguments (default: `min_niche_width = 0.1` and
`max_niche_width = 1`). If a single value or a vector of
`sd_niche_width` is provided, the function ignores `min_niche_width` and
`max_niche_width` arguments.

The argument `niche_cost` determines the cost of having wider niche.
Smaller values imply greater costs of wider niche (i.e., decreased
maximum reproductive rate; default: `niche_cost = 1`). To disable (no
cost of wide niche), set `niche_cost = Inf`.

For other parameters, users may specify species attributes by giving a
scalar (assume identical among species) or a vector of values whose
length must be one or equal to `n_species`. Default values are `r0 = 4`,
`sd_niche_width = 1`, and `p_dispersal = 0.1`.

#### Competition

Arguments: `interaction_type`, `alpha` OR `min_alpha` and `max_alpha`

The argument `interaction_type` determines whether interaction
coefficient `alpha` is a constant or random variable. If
`interaction_type = "constant"`, then the interaction coefficients
α<sub>ij</sub> (i != j) for any pairs of species will be set as a
constant `alpha` (i.e., off-diagonal elements of the interaction
matrix). If `interaction_type = "random"`, α<sub>ij</sub> will be drawn
from a uniform distribution as α<sub>ij</sub> \~
Uniform(min<sub>α</sub>, max<sub>α</sub>), where users can specify
min<sub>α</sub> and max<sub>α</sub> using arguments `min_alpha` and
`max_alpha`. The argument `alpha` is ignored under the scenario of
random interaction strength (i.e., `interaction_type = "random"`). Note
that the diagonal elements of the interaction matrix (α<sub>ii</sub>)
are always 1.0 regardless of `interaction_type`, as `alpha` is the
strength of interspecific competition relative to that of intraspecific
competition (see **Model description**). By default,
`interaction_type = "constant"` and `alpha = 0`.

#### Patch attributes

Arguments: `carrying_capacity`, `mean_env`, `sd_env`,
`spatial_auto_cor`, `phi`

The arguments `carrying_capacity` (default: `carrying_capacity = 100`)
and `mean_env` (default: `mean_env = 0`) determines mean attributes of
habitat patches, which can be a scalar (assume identical among patches)
or a vector (length must be equal to `n_patch`).

The arguments `sd_env` (default: `sd_env = 0.1`), `spatial_auto_cor`
(default: `spatial_auto_cor = FALSE`) and `phi` (default: `phi = 1`)
determine spatio-temporal dynamics of environmental values. `sd_env`
determines the magnitude of temporal environmental fluctuations. If
`spatial_auto_cor = TRUE`, the function models spatial autocorrelation
of temporal environmental fluctuation based on a multi-variate normal
distribution. The degree of spatial autocorrelation would be determined
by `phi`, the parameter describing the strength of distance decay in
spatial autocorrelation (see **Model description**).

#### Landscape structure

Arguments: `xy_coord` OR `distance_matrix` (+
`weighted_distance_matrix`), `landscape_size`, `theta`

These arguments define landscape structure. By default, the function
produces a square-shaped landscape (`landscape_size = 10` on a side) in
which habitat patches are distributed randomly through a Poisson point
process (i.e., x- and y-coordinates of patches are drawn from a uniform
distribution). The parameter θ describes the shape of distance decay in
species dispersal (see **Model description**) and determines patches’
structural connectivity (default: `theta = 1`). Users can define their
landscape by providing either `xy_coord` or `distance_matrix`
(`landscape_size` will be ignored if either of these arguments is
provided). If `xy_coord` is provided (2-column data frame denoting x-
and y-coordinates of patches, respectively; `NULL` by default), the
function calculates the distance between patches based on coordinates.
Alternatively, users may provide `distance_matrix` (the object must be
`matrix`), which describes the distance between habitat patches. The
argument `distance_matrix` overrides `xy_coord`.

`weighted_distance_matrix` is the supplemental argument to account for
asymmetry in dispersal. For example, users may set an asymmetric
distance matrix (distance between patches differs by direction, e.g.,
upstream to downstream v.s. downstream to upstream). This argument is
enabled only if both weighted (`weighted_distance_matrix`) and
unweighted distance matrix (`distance_matrix`) are given. If both
arguments are given, `weighted_distance_matrix` will be used to
calculate dispersal matrix while `distance_matrix` being used to
calculate the spatial autocorrelation in temporal environmental
variation (see **Dispersal** and **Local community dynamics** in **Model
description**).

#### Others

Arguments: `n_warmup`, `n_burnin`, `n_timestep`

The argument `n_warmup` is the period during which species introductions
occur (default: `n_warmup = 200`). The initial number of individuals
introduced follows a Poisson distribution with a mean of 0.5 and
independent across space and time. This random introduction events occur
multiple times over the `n_warmup` period, in which `propagule_interval`
determines the timestep interval of the random introductions (default:
`propagule_interval = ceiling(n_warmup / 10)`).

The argument `n_burnin` is the period that will be discarded as
*burn-in* to remove the influence of initial values (default:
`n_burnin = 200`). During the burn-in period, species introductions do
not occur.

The argument `n_timestep` is the simulation peiord that is recorded in
the return `df_dynamics` (default: `n_timestep = 1000`). As a result,
with the default setting, the function simulates 1400 timesteps
(`n_warmup` + `n_burnin` + `n_timestep` = 1400) but returns only the
last 1000 timesteps as the resulting metacommunity dynamics. All the
derived statistics (e.g., diversity metrics in `df_diversity` and
`df_patch`) will be calculated based on the results during `n_timestep`.

### Model description

The metacommunity dynamics are described as a function of local
community dynamics and dispersal (Thompson et al. 2020). Specifically,
the realized number of individuals N<sub>ix</sub>(t + 1) (species i at
patch x and time t + 1) is given as:

<img src="https://latex.codecogs.com/gif.latex?N_%7Bix%7D%28t+1%29%20%3D%20Poisson%28n_%7Bix%7D%28t%29%20+%20I_%7Bix%7D%28t%29%20-%20E_%7Bix%7D%28t%29%29"/>

where n<sub>ix</sub>(t) is the expected number of individuals given the
local community dynamics at time t, I<sub>ix</sub>(t) the expected
number of immigrants to patch x, and E<sub>ix</sub>(t) the expected
number of emigrants from patch x.

#### Local community dynamics

Local community dynamics are simulated based on the Beverton-Holt model:

<img src="https://latex.codecogs.com/gif.latex?n_%7Bix%7D%28t%29%3D%20%5Cfrac%7BN_%7Bix%7D%28t%29r_%7Bix%7D%28t%29%7D%7B1%20+%20%5Cfrac%7B%28r_0_%7Bi%7D%20-%201%29%7D%7BK_x%7D%5Csum_j%20%5Calpha_%7Bij%7D%20N_%7Bjx%7D%28t%29%7D"/>

where r<sub>ix</sub>(t) is the reproductive rate of species i given the
environmental condition at patch x and time t, r<sub>0,i</sub> the
maximum reproductive rate of species i (argument `r0`), K<sub>x</sub>
the carrying capacity at patch x (argument `carrying_capacity`), and
α<sub>ij</sub> the interaction coefficient with species j (argument
`alpha`). Note that α<sub>ij</sub> is the strength of interspecific
competition relative to that of intraspecific competition (intraspecific
competition is greater than interspecific competition if α<sub>ij</sub>
&lt; 1; α<sub>ii</sub> is set to be 1.0). The density-independent
reproductive rate r<sub>ix</sub>(t) is affected by environments and
determined by a Gaussian function:

<img src="https://latex.codecogs.com/gif.latex?r_%7Bix%7D%28t%29%20%3D%20c%7Er_%7B0%2Ci%7D%7Ee%5E%7B-%5Cfrac%7B%28%5Cmu_i-z_x%28t%29%29%5E2%7D%7B2%5Csigma_%7Bniche%2Ci%7D%5E2%7D%7D"/>

where μ<sub>i</sub> is the optimal environmental value for species i
(argument `niche_optim`), z<sub>x</sub>(t) the environmental value at
patch x and time t, and σ<sub>niche</sub> the niche width of species i
(argument `sd_niche_width`). The cost of having wider niche is expressed
by multiplying c (Chaianunporn and Hovestadt, 2015):

<img src="https://latex.codecogs.com/gif.latex?c%20%3D%20e%5E%7B-%5Cfrac%7B%5Csigma%5E2_%7Bniche%7D%7D%7B2%5Cnu%5E2%7D%7D"/>

Smaller values of ν (argument `niche_cost`) imply greater costs of wider
niche (i.e., decreased maximum reproductive rate). There is no cost of
wider niche if ν approaches infinity. The environmental value
z<sub>x</sub>(t), which may vary spatially and temporarily, is assumed
to follow a multivariate normal distribution:

<img src="https://latex.codecogs.com/gif.latex?z_%7Bx%7D%28t%29%20%5Csim%20MVN%28%5Cboldsymbol%7B%5Cmu_%7Bz%7D%7D%2C%20%5Cboldsymbol%7B%5COmega_z%7D%29"/>

**μ<sub>z</sub>** is the vector of mean environmental conditions of
patches (argument `mean_env`) and Ω<sub>z</sub> is the
variance-covariance matrix. If `spatial_auto_cor = FALSE`, the
off-diagonal elements of the matrix are set to be zero while diagonal
elements are σ<sub>z</sub><sup>2</sup> (σ<sub>z</sub>; argument
`sd_env`). If `spatial_auto_cor = TRUE`, spatial autocorrelation is
considered by describing the off-diagonal elements as:

<img src="https://latex.codecogs.com/gif.latex?%5COmega_%7Bxy%7D%20%3D%20%5Csigma_%7Bz%7D%5E2%20e%5E%7B-%5Cphi%20d_%7Bxy%7D%7D"/>

where Ω<sub>xy</sub> denotes the temporal covariance of environmental
conditions between patch x and y, which is assumed to decay
exponentially with increasing distance between the patches
d<sub>xy</sub> (randomly generated or specified by argument
`distance_matrix`). The parameter φ (argument `phi`) determines distance
decay (larger values lead to sharper declines).

#### Dispersal

The expected number of emigrants at time t E<sub>ix</sub>(t) is the
product of dispersal probability P<sub>dispersal</sub> (argument
`p_dispersal`) and n<sub>ix</sub>(t). The immigration probability at
patch x, ξ<sub>ix</sub>, is calculated given the structural connectivity
of patch x, in which the model assumes the exponential decay of
successful immigration with the increasing separation distance between
habitat patches:

<img src="https://latex.codecogs.com/gif.latex?%5Cxi_%7Bix%7D%20%28t%29%20%3D%20%5Cfrac%7B%5Csum_%7By%2C%20y%20%5Cneq%20x%7D%20E_%7Biy%7D%28t%29e%5E%7B-%5Ctheta%20d_%7Bxy%7D%7D%7D%7B%5Csum_x%20%5Csum_%7By%2C%20y%20%5Cneq%20x%7D%20E_%7Biy%7D%28t%29e%5E%7B-%5Ctheta%20d_%7Bxy%7D%7D%7D"/>

where d<sub>xy</sub> is the separation distance between patch x and y
(randomly generated or specified by argument `distance_matrix` or
`weighted_distance_matrix`). The parameter θ (argument `theta`) dictates
the dispersal distance of species (θ<sup>-1</sup> corresponds to the
expected dispersal distance) and is assumed to be constant across
species. The expected number of immigrants is calculated as:

<img src="https://latex.codecogs.com/gif.latex?I_%7Bix%7D%28t%29%20%3D%20%5Cxi_%7Bix%7D%28t%29%5Csum_x%20E_%7Bix%7D"/>

## `adjtodist`

### Basic usage

This function converts an adjacency matrix into a distance matrix.
Sample script:

``` r
net <- brnet(n_patch = 10, p_branch = 0) # linear network
```

![](README_files/figure-gfm/unnamed-chunk-22-1.png)<!-- -->

``` r
x <- net$adjacency_matrix

# adjacency matrix
print(x)
```

    ##         patch1 patch2 patch3 patch4 patch5 patch6 patch7 patch8 patch9 patch10
    ## patch1       0      1      0      0      0      0      0      0      0       0
    ## patch2       1      0      1      0      0      0      0      0      0       0
    ## patch3       0      1      0      1      0      0      0      0      0       0
    ## patch4       0      0      1      0      1      0      0      0      0       0
    ## patch5       0      0      0      1      0      1      0      0      0       0
    ## patch6       0      0      0      0      1      0      1      0      0       0
    ## patch7       0      0      0      0      0      1      0      1      0       0
    ## patch8       0      0      0      0      0      0      1      0      1       0
    ## patch9       0      0      0      0      0      0      0      1      0       1
    ## patch10      0      0      0      0      0      0      0      0      1       0

``` r
# covert an adjacency matrix into a distance matrix
adjtodist(x)
```

    ##       [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9] [,10]
    ##  [1,]    0    1    2    3    4    5    6    7    8     9
    ##  [2,]    1    0    1    2    3    4    5    6    7     8
    ##  [3,]    2    1    0    1    2    3    4    5    6     7
    ##  [4,]    3    2    1    0    1    2    3    4    5     6
    ##  [5,]    4    3    2    1    0    1    2    3    4     5
    ##  [6,]    5    4    3    2    1    0    1    2    3     4
    ##  [7,]    6    5    4    3    2    1    0    1    2     3
    ##  [8,]    7    6    5    4    3    2    1    0    1     2
    ##  [9,]    8    7    6    5    4    3    2    1    0     1
    ## [10,]    9    8    7    6    5    4    3    2    1     0

# References

-   Chaianunporn T and Hovestadt T. (2015) Evolutionary responses to
    climate change in parasitic systems. Global Change Biology 21:
    2905-2916.
-   Csardi G, Nepusz T: The igraph software package for complex network
    research, InterJournal, Complex Systems 1695. 2006.
    <http://igraph.org>
-   Jacolien van Rij (2020). plotfunctions: Various Functions to
    Facilitate Visualization of Data and Analysis. R package version
    1.4. <https://CRAN.R-project.org/package=plotfunctions>
-   Thompson, P.L., Guzman, L.M., De Meester, L., Horváth, Z., Ptacnik,
    R., Vanschoenwinkel, B., Viana, D.S. and Chase, J.M. (2020), A
    process‐based metacommunity framework linking local and regional
    scale community ecology. Ecol Lett, 23: 1314-1329.
    <doi:10.1111/ele.13568>
