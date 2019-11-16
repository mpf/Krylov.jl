# Identity matrix.
eye(n::Int) = Matrix{Float64}(I, n, n)

# Based on Lars Ruthotto's initial implementation.
function get_div_grad(n1 :: Int, n2 :: Int, n3 :: Int)

  # Divergence
  D1 = kron(eye(n3), kron(eye(n2), ddx(n1)))
  D2 = kron(eye(n3), kron(ddx(n2), eye(n1)))
  D3 = kron(ddx(n3), kron(eye(n2), eye(n1)))

  # DIV from faces to cell-centers
  Div = [D1 D2 D3]

  return Div * Div'
end

# 1D finite difference on staggered grid
function ddx(n :: Int)
  e = ones(n)
  return sparse([1:n; 1:n], [1:n; 2:n+1], [-e; e])
end

# Primal and dual ODEs discretized with central second order finite differences.
function ODE(n, f, g, ode_coefs; dim_x=[0.0, 1.0])
  # Ω = ]xₗ, xᵣ[
  # Ω ∪ ∂Ω = [xₗ, xᵣ]
  xₗ = dim_x[1]
  xᵣ = dim_x[2]

  # Uniform grid of Ω with n points
  Δx = (xᵣ - xₗ) / (n + 1)
  grid = [i * Δx for i = 1 : n]

  χ₁ = ode_coefs[1]
  χ₂ = ode_coefs[2]
  χ₃ = ode_coefs[3]

  # Modelize problems with Au = b and Aᵀv = c
  #
  # A ∈ ℜⁿ*ⁿ, u ∈ ℜⁿ, b ∈ ℜⁿ, v ∈ ℜⁿ, c ∈ ℜⁿ
  #
  # ∂²z(xᵢ) / ∂x² ≈ (zᵢ₋₁ -2zᵢ + zᵢ₊₁) / (Δx)²
  #
  # ∂z(xᵢ) / ∂x ≈ (zᵢ₊₁ - zᵢ₋₁) / (2 * Δx)
  A = spzeros(n, n)
  for i = 1 : n
    if i ≠ 1
      A[i, i-1] = χ₁ / (Δx * Δx) - χ₂ / (2 * Δx)
    end
    A[i, i] = -2 * χ₁ / (Δx * Δx) + χ₃
    if i ≠ n
      A[i, i+1] = χ₁ / (Δx * Δx) + χ₂ / (2 * Δx)
    end
  end

  b = f(grid)
  c = g(grid)
  return A, b, c
end

# Primal and dual PDEs discretized with central second order finite differences.
function PDE(n, m, f, g, pde_coefs; dim_x=[0.0, 1.0], dim_y=[0.0, 1.0])
  # Ω = ]xₗ,xᵣ[ × ]yₗ,yᵣ[
  # Ω ∪ ∂Ω = [xₗ,xᵣ] × [yₗ,yᵣ]
  xₗ = dim_x[1]
  xᵣ = dim_x[2]

  yₗ = dim_y[1]
  yᵣ = dim_y[2]

  # Uniform grid of Ω with n × m points
  Δx = (xᵣ - xₗ) / (n + 1)
  x = [xₗ + i * Δx for i = 1 : n]

  Δy = (yᵣ - yₗ) / (m + 1)
  y = [yₗ + j * Δy for j = 1 : m]

  a = pde_coefs[1]
  b = pde_coefs[2]
  c = pde_coefs[3]
  d = pde_coefs[4]
  e = pde_coefs[5]

  # Modelize problems with Au = b and Aᵀv = c
  #
  # A ∈ ℜᵐⁿ*ᵐⁿ, u ∈ ℜᵐⁿ, b ∈ ℜᵐⁿ, v ∈ ℜᵐⁿ, c ∈ ℜᵐⁿ
  # xᵢ = i * Δx, yⱼ = j * Δy and zᵢ.ⱼ = z(xᵢ, yⱼ)
  #
  # ∂²z(xᵢ, yⱼ) / ∂x² ≈ (zᵢ₋₁.ⱼ -2zᵢ.ⱼ + zᵢ₊₁.ⱼ) / (Δx)²
  # ∂²z(xᵢ, yⱼ) / ∂y² ≈ (zᵢ.ⱼ₋₁ -2zᵢ.ⱼ + zᵢ.ⱼ₊₁) / (Δy)²
  #
  # ∂z(xᵢ, yⱼ) / ∂x ≈ (zᵢ₊₁.ⱼ - zᵢ₋₁.ⱼ) / (2 * Δx)
  # ∂z(xᵢ, yⱼ) / ∂y ≈ (zᵢ.ⱼ₊₁ - zᵢ.ⱼ₋₁) / (2 * Δy)
  #
  # uᵢ.ⱼ = u[i + m * (j-1)]
  # bᵢ.ⱼ = f[i + m * (j-1)]
  #
  # vᵢ.ⱼ = v[i + m * (j-1)]
  # cᵢ.ⱼ = g[i + m * (j-1)]
  A = spzeros(n * m, n * m)
  for i = 1 : n
    for j = 1 : m
      A[i + m*(j-1), i + m*(j-1)] = - 2*a / (Δx * Δx) - 2*b / (Δy * Δy) + e
      if i ≥ 2
        A[i + m*(j-1), (i-1) + m*(j-1)] = a / (Δx * Δx) - c / (2*Δx)
      end
      if i ≤ n-1
        A[i + m*(j-1), (i+1) + m*(j-1)] = a / (Δx * Δx) + c / (2*Δx)
      end
      if j ≥ 2
        A[i + m*(j-1), i + m*(j-2)] = b / (Δy * Δy) - d / (2*Δy)
      end
      if j ≤ m-1
        A[i + m*(j-1), i + m*j] = b / (Δy * Δy) + d / (2*Δy)
      end
    end
  end

  b = zeros(n * m)
  for i = 1 : n
    for j = 1 : m
      b[i + m*(j-1)] = f(x[i], y[j])
    end
  end

  c = zeros(n * m)
  for i = 1 : n
    for j = 1 : m
      c[i + m*(j-1)] = g(x[i], y[j])
    end
  end

  return A, b, c
end
