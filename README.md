# Stheno

[![Build Status](https://travis-ci.org/willtebbutt/Stheno.jl.svg?branch=master)](https://travis-ci.org/willtebbutt/Stheno.jl)[![Windows Build Status](https://ci.appveyor.com/api/projects/status/32r7s2skrgm9ubva?svg=true)](https://ci.appveyor.com/project/willtebbutt/stheno-jl/branch/master)[![codecov.io](http://codecov.io/github/willtebbutt/Stheno.jl/coverage.svg?branch=master)](http://codecov.io/github/willtebbutt/Stheno.jl?branch=master)

Stheno is designed to make doing non-standard things with Gaussian processes straightforward. It has an intuitive modeling syntax, is inherently able to handle both multi-input and multi-output problems, trivially supports interdomain pseudo-point approximations, and has _some_ support for structure-exploiting algebra.

[We also have a Python version of the package](https://github.com/wesselb/stheno)

## A Couple of Examples

First, a note for statistics / ML people who aren't too familiar with Julia: the first execution of the examples below will take a while as Julia has to compile the code. On subsequent runs (e.g. if you were repeatedly evaluating the `logpdf` for kernel parameter learning) it will progress _much_ faster.

In this first example we define a simple Gaussian process, make observations of different bits of it, and visualise the posterior. We are trivially able to condition on both observations of both `f₁` _and_ `f₃`, which is a very non-standard capability.
```julia
using Stheno
using Stheno: @model

# Explicitly set pseudo-randomness for reproducibility.
rng = MersenneTwister(123456)

# Define a distribution over f₁, f₂, and f₃, where f₃(x) = f₁(x) + f₂(x).
@model function model()
    f₁ = GP(ConstantMean(randn(rng)), EQ())
    f₂ = GP(EQ())
    f₃ = f₁ + f₂
    return f₁, f₂, f₃
end
f₁, f₂, f₃ = model()

# Generate some toy observations of `f₁` and `f₃`.
X₁, X₃ = sort(rand(rng, 10) * 10), sort(rand(rng, 11) * 10)
ŷ₁, ŷ₃ = rand(rng, [f₁(X₁), f₃(X₃)])

# Compute the posterior processes.
(f₁′, f₂′, f₃′) = (f₁, f₂, f₃) | (f₁(X₁)←ŷ₁, f₃(X₃)←ŷ₃)

# Sample jointly from the posterior processes and compute posterior marginals.
Xp = linspace(-2.5, 12.5, 500)
f₁′Xp, f₂′Xp, f₃′Xp = rand(rng, [f₁′(Xp), f₂′(Xp), f₃′(Xp)], 25)
μf₁′, σf₁′ = marginals(f₁′(Xp))
μf₂′, σf₂′ = marginals(f₂′(Xp))
μf₃′, σf₃′ = marginals(f₃′(Xp))
```
![Alternate Text](examples/toy/process_decomposition.png)

In the above graph, we have visualised the posterior distribution of all of the processes. Bold lines are posterior means, and shaded areas are three posterior standard deviations from these means. Thin lines are samples from the posterior processes. Note that each of these samples are performed jointly.

In this next example we make observations of two different noisy versions of the same latent process. Again, this is just about doable in existing GP packages if you know what you're doing, but isn't straightforward.

```julia
using Stheno
using Stheno: @model

# Explicitly set pseudo-randomness for reproducibility.
rng = MersenneTwister(123456)

@model function model()

    # A smooth latent function.
    f = GP(EQ())

    # Two noisy processes.
    noise1 = GP(CustomMean(x->sin.(x) .- 5.0 .+ sqrt.(abs.(x))), Noise(1e-2))
    noise2 = GP(ConstantMean(3.5), Noise(1e-1))

    # Noise-corrupted versions of `f`.
    y₁ = f + noise1
    y₂ = f + noise2

    return f, noise1, noise2, y₁, y₂
end
f, noise1, noise2, y₁, y₂ = model()

# Generate some toy observations of `y₁` and `y₂`.
X₁, X₂ = sort(rand(rng, 3) * 10), sort(rand(rng, 10) * 10)
ŷ₁, ŷ₂ = rand(rng, [y₁(X₁), y₂(X₂)])

# Compute the posterior processes.
(f′, y₁′, y₂′) = (f, y₁, y₂) | (y₁(X₁)←ŷ₁, y₂(X₂)←ŷ₂)

# Sample jointly from the posterior processes and compute posterior marginals.
Xp = linspace(-2.5, 12.5, 500)
f′Xp, y₁′Xp, y₂′Xp = rand(rng, [f′(Xp), y₁′(Xp), y₂′(Xp)], 100)
μf′, σf′ = marginals(f′(Xp))
μy₁′, σy₁′ = marginals(y₁′(Xp))
μy₂′, σy₂′ = marginals(y₂′(Xp))
```
![Alternate Text](examples/toy/simple_sensor_fusion.png)

As before we visualise the posterior distribution through its marginal statistics and joint samples. Note that the posterior samples over the unobserved process are (unsurprisingly) smooth, whereas the posterior samples over the noisy processes still look uncorrelated and noise-like.


## Performance, scalability, etc

Stheno (currently) makes no claims regarding performance or scalability relative to existing Gaussian process packages. It should be viewed as a (hopefully interesting) baseline implementation for solving small-ish problems. We do provide a baseline implementation of (interdomain-) pseudo-point approximations, and can exploit Toeplitz structure in covariance matrices, but these have yet to be fully optimised.


## Non-Gaussian problems

Stheno is designed for jointly Gaussian problems, and there are no plans to support non-Gaussian likelihoods in the core package. The official stance (if you can call it that) is that since Stheno is trivially compatible with [Turing.jl](https://github.com/TuringLang/), and one should simply embed a Stheno model within a Turing model to solve non-Gaussian problems.

Example usage will be made available in the near future.


## The Elephant in the Room
You can't currently perform gradient-based kernel parameter optimisation in Stheno. This an automatic-differentiation related issue, which will definitely be resolved in 0.7 / 1.0 once [Capstan.jl](https://github.com/JuliaDiff/Capstan.jl) or some other [Cassette.jl](https://github.com/jrevels/Cassette.jl)-based AD package is available. There's not a lot more to say than that really. Apologies.
