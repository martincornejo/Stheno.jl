using Stheno: unbox

@testset "covariance_matrices" begin

    let
        rng, N, P, Q = MersenneTwister(123456), 5, 6, 2
        B = randn(rng, N, N)
        A_ = B' * B + UniformScaling(1e-6)
        U = chol(A_)
        @test 2 * logdet(U) ≈ logdet(A_)
    end

    # Test that the AbstractArray interface works.
    let
        rng, N, P, Q = MersenneTwister(123456), 5, 6, 2
        B = randn(rng, N, N)
        Σ_ = B' * B + 1e-6I
        Σ = LazyPDMat(Σ_)

        @test size(Σ) == (N, N)
        @test getindex(Σ, 10) == getindex(Σ_, 10)
    end

    # Test strided matrix functionality.
    let
        # Set up some matrices.
        rng, N, P, Q = MersenneTwister(123456), 5, 6, 2
        B = randn(rng, N, N)
        A_ = B' * B + UniformScaling(1e-6)
        A = LazyPDMat(A_)
        x, X, Y = randn(rng, N), randn(rng, N, P), randn(rng, N, Q)

        # Check utility functionality.
        @test LazyPDMat(A) === A
        @test LazyPDMat(5.0) === 5.0
        @test unbox(A) === A_
        @test size(A) == size(A_)
        @test size(A, 1) == size(A_, 1)
        @test size(A, 2) == size(A_, 2)
        
        @test A == A
        @test A ≈ A

        # Test unary operations.
        @test logdet(A) ≈ logdet(A_)
        @test chol(A) == chol(A_ + A.ϵ * I)

        # Test binary operations.
        @test typeof(A + A) <: LazyPDMat
        @test unbox(A + A) == A_ + A_
        @test A + 0.5I isa LazyPDMat
        @test A + (-0.5) * I isa Matrix
        @test unbox(A + 0.5I) == unbox(A) + 0.5I
        @test typeof(A * A) <: LazyPDMat
        @test unbox(A * A) == A_ * A_
        @test map(*, A, A) isa LazyPDMat
        @test unbox(map(*, A, A)) == map(*, unbox(A), unbox(A))
        @test typeof(map(*, A, A)) <: LazyPDMat
        @test map(*, A, A) == LazyPDMat(map(*, A_, A_))
        @test typeof(broadcast(*, A, A)) <: LazyPDMat
        @test broadcast(*, A, A) == LazyPDMat(A_ .* A_)

        # Specialised matrix operations.
        @test Xt_A_X(A, X) isa LazyPDMat
        @test Xt_invA_X(A, X) isa LazyPDMat
        @test Xt_invA_X(A, X[:, 1]) isa Real
        @test X' * A_ * X ≈ unbox(Xt_A_X(A, X))
        @test X' * A * Y ≈ Xt_A_Y(X, A, Y)
        @test X' * (A_ \ X) ≈ unbox(Xt_invA_X(A, X))
        @test X' * (A_ \ Y) ≈ Xt_invA_Y(X, A, Y)
        @test A_ \ X ≈ A \ X
    end

    # Test misc. operations.
    let
        rng, N, N′, D = MersenneTwister(123456), 7, 8, 4
        X, Y = randn(rng, D, N), randn(rng, D, N)

        # Construct PD matrix.
        B = randn(rng, D, D)
        A_ = B' * B + UniformScaling(1e-6)
        A = LazyPDMat(A_)

        @test Stheno.diag_AᵀA(X) ≈ diag(X'X)
        @test Stheno.diag_AᵀB(X, Y) ≈ diag(X'Y)

        @test Stheno.diag_Xᵀ_invA_X(A, X) ≈ diag(Xt_invA_X(A, X))
        @test Stheno.diag_Xᵀ_invA_Y(X, A, Y) ≈ diag(Xt_invA_Y(X, A, Y))
    end

end
