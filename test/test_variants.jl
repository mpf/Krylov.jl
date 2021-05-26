@testset "variants" begin
  for fn in (:cg_lanczos, :cg, :cgls, :cgne, :cr, :lnlq, :craig,
             :craigmr, :crls, :crmr, :lslq, :lsmr, :bilq, :lsqr,
             :minres, :symmlq, :dqgmres, :diom, :cgs, :bicgstab, :usymqr,
             :minres_qlp, :qmr, :usymlq, :bilqr, :tricg, :trimr, :trilqr)
    for T in (Float32, Float64, BigFloat)
      for S in (Int32, Int64)
        A_dense = Matrix{T}(I, 5, 5)
        A_sparse = convert(SparseMatrixCSC{T,S}, A_dense)
        b_dense = ones(T, 5)
        b_sparse = convert(SparseVector{T,S}, b_dense)
        b_view = view(b_dense, 1:5)
        for A in (A_dense, A_sparse)
          for b in (b_dense, b_sparse, b_view)
            if fn in (:usymlq, :usymqr, :tricg, :trimr, :trilqr, :bilqr)
              c_dense = ones(T, 5)
              c_sparse = convert(SparseVector{T,S}, c_dense)
              c_view = view(c_dense, 1:5)
              for c in (c_dense, c_sparse, c_view)
                @eval $fn($A, $b, $c)
                @eval $fn($transpose($A), $b, $c)
                @eval $fn($adjoint($A), $b, $c)
              end
            else
              @eval $fn($A, $b)
              @eval $fn($transpose($A), $b)
              @eval $fn($adjoint($A), $b)
              if fn == :cg_lanczos
                shifts = [-one(T), one(T)]
                @eval $fn($A, $b, $shifts)
                @eval $fn($transpose($A), $b, $shifts)
                @eval $fn($adjoint($A), $b, $shifts)
              end
            end
          end
        end
      end
    end
  end
end
