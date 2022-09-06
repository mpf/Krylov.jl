@testset "qmr" begin
  qmr_tol = 1.0e-6

  for FC in (Float64, ComplexF64)
    @testset "Data Type: $FC" begin

      # Symmetric and positive definite system.
      A, b = symmetric_definite(FC=FC)
      (x, stats) = qmr(A, b)
      r = b - A * x
      resid = norm(r) / norm(b)
      @test(resid ≤ qmr_tol)
      @test(stats.solved)

      # Symmetric indefinite variant.
      A, b = symmetric_indefinite(FC=FC)
      (x, stats) = qmr(A, b)
      r = b - A * x
      resid = norm(r) / norm(b)
      @test(resid ≤ qmr_tol)
      @test(stats.solved)

      # Nonsymmetric and positive definite systems.
      A, b = nonsymmetric_definite(FC=FC)
      (x, stats) = qmr(A, b)
      r = b - A * x
      resid = norm(r) / norm(b)
      @test(resid ≤ qmr_tol)
      @test(stats.solved)

      # Nonsymmetric indefinite variant.
      A, b = nonsymmetric_indefinite(FC=FC)
      (x, stats) = qmr(A, b)
      r = b - A * x
      resid = norm(r) / norm(b)
      @test(resid ≤ qmr_tol)
      @test(stats.solved)

      # Sparse Laplacian.
      A, b = sparse_laplacian(FC=FC)
      (x, stats) = qmr(A, b)
      r = b - A * x
      resid = norm(r) / norm(b)
      @test(resid ≤ qmr_tol)
      @test(stats.solved)

      # Test b == 0
      A, b = zero_rhs(FC=FC)
      (x, stats) = qmr(A, b)
      @test norm(x) == 0
      @test stats.status == "x = 0 is a zero-residual solution"

      # Poisson equation in polar coordinates.
      A, b = polar_poisson(FC=FC)
      (x, stats) = qmr(A, b)
      r = b - A * x
      resid = norm(r) / norm(b)
      @test(resid ≤ qmr_tol)
      @test(stats.solved)

      # Test bᴴc == 0
      A, b, c = bc_breakdown(FC=FC)
      (x, stats) = qmr(A, b, c=c)
      @test stats.status == "Breakdown bᴴc = 0"

      # test callback function
      solver = QmrSolver(A, b)
      tol = 1.0e-1
      cb_n2 = TestCallbackN2(A, b, tol = tol)
      qmr!(solver, A, b, callback = cb_n2)
      @test solver.stats.status == "user-requested exit"
      @test cb_n2(solver)

      @test_throws TypeError qmr(A, b, callback = solver -> "string", history = true)
    end
  end
end
