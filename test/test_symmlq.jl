@testset "symmlq" begin
  symmlq_tol = 1.0e-6

  for FC in (Float64, ComplexF64)
    @testset "Data Type: $FC" begin

      # Symmetric and positive definite system.
      n = 10
      A, b = symmetric_definite(FC=FC)
      (x, stats) = symmlq(A, b)
      r = b - A * x
      resid = norm(r) / norm(b)
      @test(resid ≤ symmlq_tol)
      @test(stats.solved)

      # Symmetric indefinite variant.
      A, b = symmetric_indefinite(FC=FC)
      (x, stats) = symmlq(A, b)
      r = b - A * x
      resid = norm(r) / norm(b)
      @test(resid ≤ symmlq_tol)
      @test(stats.solved)

      # Sparse Laplacian.
      A, b = sparse_laplacian(FC=FC)
      (x, stats) = symmlq(A, b, atol=1e-12, rtol=1e-12)
      r = b - A * x
      resid = norm(r) / norm(b)
      @test(resid ≤ 100 * symmlq_tol)
      @test(stats.solved)

      # System that cause a breakdown with the symmetric Lanczos process.
      A, b = symmetric_breakdown(FC=FC)
      (x, stats) = symmlq(A, b)
      r = b - A * x
      resid = norm(r) / norm(b)
      @test(resid ≤ symmlq_tol)
      @test(stats.solved)

      # Test b == 0
      A, b = zero_rhs(FC=FC)
      (x, stats) = symmlq(A, b)
      @test norm(x) == 0
      @test stats.status == "x = 0 is a zero-residual solution"

      # Test error estimate
      A = Matrix(get_div_grad(8, 8, 8))
      b = ones(size(A, 1))
      λest = (1 - 1e-10) * eigmin(A)
      x_exact = A \ b
      (xlq, stats) = symmlq(A, b, λest=λest, transfer_to_cg=false, history=true)
      xcg = cg(A, b)[1]
      err = norm(x_exact - xlq)
      errcg = norm(x_exact - xcg)
      @test( err ≤ stats.errors[end] )
      @test( errcg ≤ stats.errorscg[end])
      (x, stats) = symmlq(A, b, λest=λest, window=1, history=true)
      @test( err ≤ stats.errors[end] )
      @test( errcg ≤ stats.errorscg[end])
      (x, stats) = symmlq(A, b, λest=λest, window=5, history=true)
      @test( err ≤ stats.errors[end] )
      @test( errcg ≤ stats.errorscg[end])

      # Test with Jacobi (or diagonal) preconditioner
      A, b, M = square_preconditioned(FC=FC)
      (x, stats) = symmlq(A, b, M=M)
      r = b - A * x
      resid = norm(r) / norm(b)
      @test(resid ≤ symmlq_tol)
      @test(stats.solved)

      # test callback function
      solver = SymmlqSolver(A, b)
      storage_vec = similar(b, size(A, 1))
      tol = 1.0
      symmlq!(solver, A, b, atol = 0.0, rtol = 0.0,
              callback = (args...) -> test_callback_n2(args..., storage_vec = storage_vec, tol = tol))
      @test solver.stats.status == "user-requested exit"
      @test test_callback_n2(solver, A, b, storage_vec = storage_vec, tol = tol)

      @test_throws TypeError symmlq(A, b, callback = (args...) -> "string", history = true)
    end
  end
end
