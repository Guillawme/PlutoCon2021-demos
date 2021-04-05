### A Pluto.jl notebook ###
# v0.14.0

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ c456b902-7959-11eb-03ba-dd14a2cd5758
begin
	using Revise, PlutoUI, CoordinateTransformations, StaticArrays, Rotations, Viznet, Compose
	# left right layout
	function leftright(a, b; width=600)
		HTML("""
<style>
table.nohover tr:hover td {
   background-color: white !important;
}</style>
			
<table width=$(width)px class="nohover" style="border:none">
<tr>
	<td>$(html(a))</td>
	<td>$(html(b))</td>
</tr></table>
""")
	end
	
	# up down layout
	function updown(a, b; width=nothing)
		HTML("""<table class="nohover" style="border:none" $(width === nothing ? "" : "width=$(width)px")>
<tr>
	<td>$(html(a))</td>
</tr>
<tr>
	<td>$(html(b))</td>
</tr></table>
""")
	end
	
	function highlight(str)
		HTML("""<span style="background-color:yellow">$(str)</span>""")
	end
end;

# ╔═╡ 5bb40ad6-7b33-11eb-0b31-63d5e47fa0e7
using TropicalNumbers, 			# tropical number type
		TropicalGEMM, 		    # fast tropical matrix multiplication
		LightGraphs,			# graph operations
    	SimpleTensorNetworks,  	# tensor network contraction
		Random

# ╔═╡ 121b4926-7aba-11eb-30e1-7b8edd4f0166
html"""<h1>Tropical tensor networks for solving spin glasses</h1>
<p><big>Jinguo Liu</big></p>
"""

# ╔═╡ 92065f9d-422e-455f-bff2-f442ccd6043a
md"""
1. What is a tropical tensor network,
2. How to use a tropical tensor network to find the spin glass ground state,
3. How to use a tropical tensor network to count the spin glass ground state degeneracy,
"""

# ╔═╡ 9273e259-a25a-46a4-b0f8-62f37f62c263
html"""<button onclick="present()">present</button>"""

# ╔═╡ 2c3f2fd6-93ea-4fd7-9664-cffd10db16b4
html"""
<script>
document.body.style.cursor = "pointer";
</script>
"""

# ╔═╡ 7bdf517e-79ff-11eb-38a3-49c02d94d943
md"## The Song Shan Lake Spring School (SSSS) Challenge"

# ╔═╡ 89d737b3-e72e-4d87-9ade-466a84491ac8
md"In 2019, Lei Wang, Pan Zhang, Roger and me released a challenge in the Song Shan Lake Spring School, the one gives the largest number of solutions to the challenge quiz can take a macbook home ([@LinuxDaFaHao](https://github.com/LinuxDaFaHao)). Students submitted many [solutions to the problem](https://github.com/QuantumBFS/SSSS/blob/master/Challenge.md). The second part of the quiz is"

# ╔═╡ a843152e-93e6-11eb-365f-2bd3ff0cf096
md"""
θ = $(@bind θ2 Slider(0.0:0.01:π; default=0.5))

ϕ = $(@bind ϕ2 Slider(0.0:0.01:2π; default=0.3))
"""

# ╔═╡ 88e14ef2-7af1-11eb-23d6-b34b1eff8f87
md"""
In the $(highlight("Buckyball")) structure shown in the figure, we attach an ising spin ``s_i=\pm 1`` on each vertex. The neighboring spins interact with an $(highlight("anti-ferromagnetic")) coupling of unit strength. Count the $(highlight("degeneracy")) of configurations that minimizes the energy
```math
E(\{s_1,s_2,\ldots,s_n\}) = \sum_{i,j \in edges}s_i s_j
```
"""

# ╔═╡ 3221a326-7a17-11eb-0fe6-f75798a411b9
md"""# A tropical tensor network approach
"""

# ╔═╡ e383103e-c956-4884-9c59-3e171b5bc11d
highlight("A tensor network is a generalization of matrix multiplication")

# ╔═╡ 3208fd8a-7a17-11eb-35ce-4d6b141c1aff
md"
```math
Y[i,j] := \sum_k A[i,k] \times B[k,j]
```
"

# ╔═╡ 32116a92-7a17-11eb-228f-0713510d0348
let
	Compose.set_default_graphic_size(15cm, 10/3*cm)
	sq = nodestyle(:square; r=0.08)
	eb = bondstyle(:line)
	tb = textstyle(:default, fontsize(20px))
	tb2 = textstyle(:default, fontsize(30px), fill("white"))
	y0 = 0.15
	x = (0.3, y0)
	y = (0.7, y0)
	img = canvas() do
		sq >> x
		sq >> y
		eb >> (x, y)
		eb >> (x, (0.0, y0))
		eb >> (x, (1.0, y0))
		tb >> ((0.1, y0+0.05), "i")
		tb >> ((0.9, y0+0.05), "j")
		tb >> ((0.5, y0+0.05), "k")
		tb2 >> (x, "A")
		tb2 >> (y, "B")
	end
	Compose.compose(context(0.38, 0.0, 1/1.5^2, 2.0), img)
end


# ╔═╡ 1af9b822-4239-4ac7-bc64-801a3461d9e1
md"""

* matrices → tensors
* two arguments → multiple arguments

```math
Y[n] := \sum_{i,j,k,l,m} A[i,l] \times B[i,j] \times C[j,k,n] \times D[k,l,m] \times E[m]
```
"""

# ╔═╡ 32277c3a-7a17-11eb-3763-af68dbb81465
let
	Compose.set_default_graphic_size(14cm, 7cm)
	sq = nodestyle(:square; r=0.07)
	wb = nodestyle(:square, fill("white"); r=0.04)
	eb = bondstyle(:line)
	tb = textstyle(:default, fontsize(25px))
	tb2 = textstyle(:default, fontsize(30px), fill("white"))
	x0 = 0.15
	x1 = 0.65
	y0 = 0.35
	y1 = 0.8
	x3 = 0.9
	y3 = 0.1
	a = (x0, y0)
	b = (x0, y1)
	c = (x1, y1)
	d = (x1, y0)
	e = (x3, y3)
	img = canvas() do
		for (loc, label) in [(a, "A"), (b, "B"), (c, "C"), (d, "D"), (e, "E")]
			sq >> loc
			tb2 >> (loc, label)
		end
		for (edge, label) in [((a, b), "i"), ((b, c), "j"), ((c, d), "k"), ((a, d), "l"), ((d,e), "m"), ((c, (0.9, 0.55)), "n")]
			eb >> edge
			wb >> ((edge[1] .+ edge[2]) ./ 2)
			tb >> ((edge[1] .+ edge[2]) ./ 2, label)
		end
	end
	Compose.compose(context(.38, 0, .5, 1), img)
end

# ╔═╡ 2c294933-1425-4e80-84f8-80fe73b2b03a
md"""A tensor network is also a $(highlight("sum-product")) of tensor elements."""

# ╔═╡ a7363a47-83b6-458a-95dc-448f32d4ef4f
highlight("A Tropical tensor network is a tensor network with Tropical numbers as tensor elements.")

# ╔═╡ d0b54b76-7852-11eb-2398-0911380fa090
md"""

```math
\begin{align}
&a ⊕ b = \max(a, b)\\
&a ⊙ b = a + b
\end{align}
```
"""

# ╔═╡ 211911da-7a18-11eb-12d4-65b0dec4b8dc
md"
```math
\begin{align}
\cancel{Y[n] := \sum_{i,j,k,l,m} A[i,l] \times B[i,j] \times C[j,k,n] \times D[k,l,m] \times E[m]}\\

Y[n] := \max_{i,j,k,l,m} (A[i,l] + B[i,j] + C[j,k,n] + D[k,l,m] + E[m])
\end{align}
```
"

# ╔═╡ 31b975b8-690d-41a0-b1a4-dcbf16a23517
md"""
It has the same form as the spinglass ground state problem.
```math
-E_G = \max_{\{s_1,s_2,\ldots,s_n\}}\left(-\sum_{ij \in edges}J_{ij}s_i s_j\right)
```
"""

# ╔═╡ 5f6cfe59-4d59-4ee6-a32c-712e2a67faa5
md"""
## Let's get our hands dirty!
"""

# ╔═╡ 5d956bd2-8472-47dc-909a-7930612e66de
md"## Tropical algebra"

# ╔═╡ 0b15c4a8-c4b3-4dc3-8aba-61222a48fd05
md"x = $(@bind x Slider(-10:0.1:10; default=3.0,show_value=true))"

# ╔═╡ 7a88b8f0-6f22-4992-931b-54e7f50742f0
zero(TropicalF64)

# ╔═╡ d770f232-7864-11eb-0e9a-81528e359d39
Tropical(-Inf) + Tropical(x)

# ╔═╡ 8168345f-67de-46ca-b9c9-a77ca838da74
Tropical(-Inf) * Tropical(x)

# ╔═╡ 8767709c-478d-4fe5-ad6b-a280b9443460
one(TropicalF64)

# ╔═╡ af13e090-7852-11eb-21ae-8b94f25f1a4f
Tropical(0.0) * Tropical(x)

# ╔═╡ f59579f4-7163-415e-a5f3-18531084af45
Tropical(2.0) - Tropical(1.0)

# ╔═╡ 695e405c-786d-11eb-0a6e-bb776d9626ad
md"
# Counting degeneracy
"

# ╔═╡ 01e40898-c1c8-481a-b149-9b1bebb00043
md"""
Tropical algebra with $(highlight("degeneracy counting"))
```math
\begin{align}
(n_1, c_1) \odot (n_2,c_2) &= (n_1 + n_2, c_1\cdot c_2),\\
    (n_1, c_1)\oplus (n_2, c_2) &= \begin{cases}
 (n_1\oplus n_2, \, c_1 + c_2 ) & \text{if $n_1 = n_2$}, \\
 (n_1\oplus n_2,\, c_1 ) & \text{if $n_1>n_2$}, \\
 (n_1\oplus n_2,\, c_2 )& \text{if $n_1 < n_2$}.
 \end{cases}
\end{align}
```
"""

# ╔═╡ 1bb36c52-a171-4993-ac86-2250e1e87a01
md"It corresponds to the following four processes of concatenating and comparing configrations on graphs (or tensor networks)."

# ╔═╡ 43101224-7ac5-11eb-104c-0323cf1813c5
md"The zero and one elements are defined as"

# ╔═╡ a0b3eec1-2ab5-4166-b27d-1e0968c1f06e
CountingTropical(2.0)

# ╔═╡ 792df1aa-7a23-11eb-2991-196336246c43
zero(CountingTropical{Float64})

# ╔═╡ 8388305c-7a23-11eb-1588-79c3c6ce9db9
one(CountingTropical{Float64})

# ╔═╡ 7b618d71-2b56-42ba-9c3a-5840f4f0d481
md"## Mapping a spin glass to a Tropical tensor network"

# ╔═╡ b52ead96-7a2a-11eb-334f-e5e5ff5867e3
let
	B = md"""
```math
T_{e_{i,j}} = \begin{bmatrix}-J_{ij} & J_{ij} \\J_{ij} & -J_{ij}\end{bmatrix}
```
"""
	A = md"""
```math
(T_{v_i})_{s_i s_i' s_i''} = \begin{cases}
 0, & s_i = s_i' =s_i''\\
 -\infty, &otherwise
\end{cases}
```
"""
	leftright(updown(html"<p align='center'>vertex tensor</p>", A), updown(html"<p align='center'>edge tensor</p>", B))
end

# ╔═╡ b975680f-0b78-4178-861f-5da6d10327e4
function ising_vertextensor(::Type{T}, n::Int) where T
	res = zeros(T, fill(2, n)...)
	res[1] = one(T)
	res[end] = one(T)
	return res
end

# ╔═╡ e0939f0e-d9f5-4ec6-937d-66367fb40fb6
ising_vertextensor(TropicalF64, 3)

# ╔═╡ 624f57db-7f07-4281-a547-d229b9a8413a
function ising_bondtensor(::Type{T}, J) where T
	e = T(-J)
	e_ = T(J)
	[e e_; e_ e]
end

# ╔═╡ 8692573b-ae74-4f24-8bc3-57c7b85a7034
ising_bondtensor(TropicalF64, 1.0)

# ╔═╡ 064c14b0-73db-4bcf-9b64-a0e34c642f97
md"The contraction gives you the negation of ground state energy"

# ╔═╡ 16c2b86c-db2d-4408-a6ae-e698fdd495c7
md"""
```math
\begin{align}
&\max_{\{s_1,s_2\ldots s_n\}} \sum_{i\in vertices}(T_{v})_{s_is_i s_i} + \sum_{ij\in edges}(T_{e_{ij}})_{s_is_j}\\
=&\max_{\{s_1,s_2,\ldots,s_n\}}\left(-\sum_{ij \in edges}J_{ij}s_i s_j\right)
\end{align}
```
"""

# ╔═╡ 35a94847-a048-44fa-944c-33e6c397bf40
md"# Solving the Buckyball chanllenge step by step"

# ╔═╡ 88f59918-a0e0-4be4-be0a-06b86b90ad58
md"## Step 1: Generate the tensor network"

# ╔═╡ 5a5d4de6-7895-11eb-15c6-bda7a4342002
# returns atom locations
function fullerene()
	φ = (1+√5)/2
	res = NTuple{3,Float64}[]
	for (x, y, z) in ((0.0, 1.0, 3φ), (1.0, 2 + φ, 2φ), (φ, 2.0, 2φ + 1.0))
		for (α, β, γ) in ((x,y,z), (y,z,x), (z,x,y))
			for loc in ((α,β,γ), (α,β,-γ), (α,-β,γ), (α,-β,-γ), (-α,β,γ), (-α,β,-γ), (-α,-β,γ), (-α,-β,-γ))
				if loc ∉ res
					push!(res, loc)
				end
			end
		end
	end
	return res
end;

# ╔═╡ 9b1dc21a-7896-11eb-21f6-bfe9b4dc9ccf
let
	tb = textstyle(:default)
	Compose.set_default_graphic_size(14cm, 8cm)
	cam_position = SVector(0.0, 0.0, 0.5)
	rot = RotY(θ2)*RotX(ϕ2)
	cam_transform = PerspectiveMap() ∘ inv(AffineMap(rot, rot*cam_position))
	Nx = Ny = Nz = 4
	nb = nodestyle(:circle; r=0.01)
	eb = bondstyle(:default; r=0.01)
	x(i,j,k) = cam_transform(SVector(i,j,k) .* 0.03).data
	fl = fullerene()
	fig = canvas() do
		for (i,j,k) in fl
			nb >> x(i,j,k)
			for (i2,j2,k2) in fl
				(i2-i)^2+(j2-j)^2+(k2-k)^2 < 5.0 && eb >> (x(i,j,k), x(i2,j2,k2))
			end
		end
		tb >> ((0.4, 0.2), "60 vertices\n90 edges")
		nb >> (0.4, -0.1)
		tb >> ((0.55, -0.1), "Ising spin (s=±1)")
		eb >> ((0.37, -0.05), (0.43, -0.05))
		tb >> ((0.54, -0.05), "AFM coupling")
	end
	img = Compose.compose(context(0.3,0.5, 1.2/1.4, 1.5), fig)
	img
end

# ╔═╡ acbdbfa8-97bc-4194-81b9-4a203e7f8919
let
	tb = textstyle(:default)
	mb = textstyle(:math)
	Compose.set_default_graphic_size(14cm, 8cm)
	cam_position = SVector(0.0, 0.0, 0.5)
	rot = RotY(θ2)*RotX(ϕ2)
	cam_transform = PerspectiveMap() ∘ inv(AffineMap(rot, rot*cam_position))
	Nx = Ny = Nz = 4
	nb1 = nodestyle(:circle; r=0.01)
	nb2 = nodestyle(:square; r=0.01)
	eb = bondstyle(:default; r=0.01)
	x(i,j,k) = cam_transform(SVector(i,j,k) .* 0.03).data
	fl = fullerene()
	fig = canvas() do
		for (i,j,k) in fl
			nb1 >> x(i,j,k)
			for (i2,j2,k2) in fl
				if (i2-i)^2+(j2-j)^2+(k2-k)^2 < 5.0 && (i<=i2 && (i,j,k) != (i2,j2,k2))
					eb >> (x(i,j,k), x(i2,j2,k2))
					nb2 >> x((i+i2)/2,(j+j2)/2,(k+k2)/2)
				end
			end
		end
		nb1 >> (0.4,-0.1)
		eb >> ((0.35,-0.1), (0.45, -0.1))
		nb2 >> (0.4,0.0)
		eb >> ((0.35,-0.0), (0.45, -0.0))
		tb >> ((0.54, 0.0), "edge tensor")
		tb >> ((0.55, -0.1), "vertex tensor")
	end
	img = Compose.compose(context(0.3,0.5, 1.2/1.4, 1.5), fig)
	img
end

# ╔═╡ b6560404-7b2d-11eb-21d7-a1e55609ebf7
# the positions of fullerene atoms
c60_xy = fullerene();

# ╔═╡ 6f649efc-7b2d-11eb-1e80-53d84ef98c13
# find edges: vertex pairs with square distance smaller than 5.
c60_edges = [(i=>j) for (i,(i2,j2,k2)) in enumerate(c60_xy), (j,(i1,j1,k1)) in enumerate(c60_xy) if i<j && (i2-i1)^2+(j2-j1)^2+(k2-k1)^2 < 5.0];

# ╔═╡ 20125640-79fd-11eb-1715-1d071cc6cf6c
md"The resulting tensor network contains 90 edge tensors and 60 vertex tensors."

# ╔═╡ c26b5bb6-7984-11eb-18fe-2b6a524f5c85
function c60_tnet(::Type{T}) where T
	vertex_arrays = [ising_vertextensor(T, 3) for j=1:length(c60_xy)]
	edge_arrays = [ising_bondtensor(T, 1.0) for i = 1:length(c60_edges)]
	TensorNetwork([
		# vertex tensors
		[LabeledTensor(vertex_arrays[i], [(j, v==e[1]) for (j, e) in enumerate(c60_edges) if v ∈ e]) for (i, v) in enumerate(1:60)]...,
		# bond tensors
		[LabeledTensor(edge_arrays[j], [(j, true), (j, false)]) for j=1:length(c60_edges)]...
	])
end;

# ╔═╡ 07a6ac8b-1663-4f07-9434-8915f7f529e1
c60_tnet(TropicalF64) |> length

# ╔═╡ 698a6dd0-7a0e-11eb-2766-1f0baa1317d2
md"## Step 2: Find a proper contraction order by greedy search"

# ╔═╡ 020cfb20-8228-11eb-2ee9-6de0fc7700b1
md"Seed for greedy search = $(@bind seed Slider(1:10000; show_value=true, default=42))"

# ╔═╡ ae92d828-7984-11eb-31c8-8b3f9a071c24
tcs, scs, c60_trees = (Random.seed!(seed); trees_greedy(c60_tnet(TropicalF64); strategy="min_reduce"));

# ╔═╡ 12740186-7b2f-11eb-35e4-01e6f9ffbb4d
c60_contraction_masks = let
	function contraction_mask(tnet, tree)
		contraction_mask!(tnet, tree, [zeros(Bool, length(tnet))])
	end
	function contraction_mask!(tnet, tree, results)
		if tree isa Integer
			res = copy(results[end])
			@assert res[tree] == false
			res[tree] = true
			push!(results, res)
		else
			contraction_mask!(tnet, tree.left, results)
			contraction_mask!(tnet, tree.right, results)
		end
		return results
	end
	contraction_mask(c60_tnet(TropicalF64), c60_trees[])
end;

# ╔═╡ 58e38656-7b2e-11eb-3c70-25a919f9926a
md"contraction step = $(@bind nstep_c60 Slider(0:length(c60_tnet(TropicalF64)); show_value=true, default=60))"

# ╔═╡ 2b899624-798c-11eb-20c4-fd5523f7abff
md"The resulting contraction order produces time complexity = 2^ $(round(log2sumexp2(tcs); sigdigits=4)), space complexity = 2^ $(round(maximum(scs); sigdigits=4))"

# ╔═╡ c1c74e70-7b2c-11eb-2f26-21f54ad00fb2
let
	θ2 = 0.5
	ϕ2 = 0.8
	mask = c60_contraction_masks[nstep_c60+1]
	Compose.set_default_graphic_size(12cm, 12cm)
	cam_position = SVector(0.0, 0.0, 0.5)
	rot = RotY(θ2)*RotX(ϕ2)
	cam_transform = PerspectiveMap() ∘ inv(AffineMap(rot, rot*cam_position))
	Nx = Ny = Nz = 4
	tb = textstyle(:default)
	nb1 = nodestyle(:circle, fill("red"); r=0.01)
	nb2 = nodestyle(:circle, fill("white"), stroke("black"); r=0.01)
	eb = bondstyle(:default; r=0.01)
	x(i,j,k) = cam_transform(SVector(i,j,k) .* 0.03).data
	
	fig = canvas() do
		for (s, (i,j,k)) in enumerate(c60_xy)
			(mask[s] ? nb1 : nb2) >> x(i,j,k)
		end
		for (i, j) in c60_edges
			eb >> (x(c60_xy[i]...), x(c60_xy[j]...))
		end
		nb1 >> (-0.1, 0.45)
		tb >> ((-0.0, 0.45), "contracted")
		nb2 >> (-0.1, 0.50)
		tb >> ((-0.0, 0.50), "remaining")
	end
	Compose.compose(context(0.5,0.35, 1.0, 1.0), fig)
end

# ╔═╡ aed5727a-744f-4b41-96a8-1c193bd42d68
md"## Step 3: Do the contraction!"

# ╔═╡ 1332bc4c-8dfd-4022-8a40-413a85898b2a
md"For the negated ground state energy only"

# ╔═╡ 8522456a-823c-11eb-3cc1-fb720f1cc470
SimpleTensorNetworks.contract(c60_tnet(TropicalF64), c60_trees[]).array[]

# ╔═╡ 0eb9b484-8270-40ed-ad5c-df342467e51a
md"For the ground state energy degeneracy"

# ╔═╡ c18b54d5-3dc3-4977-841b-5a73215306d6
SimpleTensorNetworks.contract(c60_tnet(CountingTropicalF64), c60_trees[]).array[]

# ╔═╡ 1c4b19d2-7b30-11eb-007b-ab03052b22d2
md"If you see a 16000 in the counting field, congratuations!"

# ╔═╡ e302bd1c-7ab5-11eb-03f6-69dcbb817354
md"## Resources

* Papers and notebooks
    * [Phys. Rev. Lett. 126, 090506 (2021)](https://journals.aps.org/prl/abstract/10.1103/PhysRevLett.126.090506), Jin-Guo Liu, Lei Wang, and Pan Zhang
    * [notebook](https://giggleliu.github.io/notebooks/tropical/tropicaltensornetwork.html)
* Learn Tensor networks
    * [Tensor network website](https://tensornetwork.org/)
    * How to find a good tensor contraction order?
        * [Contracting Arbitrary Tensor Networks: General Approximate Algorithm and Applications in Graphical Models and Quantum Circuit Simulations](https://journals.aps.org/prl/abstract/10.1103/PhysRevLett.125.060503)
* Learn more about spin glasses and other hard problems
"

# ╔═╡ 442bcb3c-7940-11eb-18e5-d3158b74b1dc
html"""
<table style="border:none">
<tr>
	<td rowspan=4>
	<img src="https://images-na.ssl-images-amazon.com/images/I/51QttTd6JLL._SX351_BO1,204,203,200_.jpg" width=200px/>
	</td>
	<td rowspan=1 align="center">
	<big>The Nature of Computation</big><br><br>
	By <strong>Cristopher Moore</strong>
	</td>
</tr>
<tr>
	<td align="center">
	<strong>Section 5</strong>
	<br><br>Who is the hardest one of All?
	<br>NP-Completeness
	</td>
</tr>
<tr>
	<td align="center">
	<strong>Section 13</strong>
	<br><br>Counting, sampling and statistical physics
	</td>
</tr>
</table>
"""

# ╔═╡ Cell order:
# ╠═c456b902-7959-11eb-03ba-dd14a2cd5758
# ╟─121b4926-7aba-11eb-30e1-7b8edd4f0166
# ╟─92065f9d-422e-455f-bff2-f442ccd6043a
# ╟─9273e259-a25a-46a4-b0f8-62f37f62c263
# ╟─2c3f2fd6-93ea-4fd7-9664-cffd10db16b4
# ╟─7bdf517e-79ff-11eb-38a3-49c02d94d943
# ╟─89d737b3-e72e-4d87-9ade-466a84491ac8
# ╟─9b1dc21a-7896-11eb-21f6-bfe9b4dc9ccf
# ╟─a843152e-93e6-11eb-365f-2bd3ff0cf096
# ╟─88e14ef2-7af1-11eb-23d6-b34b1eff8f87
# ╟─3221a326-7a17-11eb-0fe6-f75798a411b9
# ╟─e383103e-c956-4884-9c59-3e171b5bc11d
# ╟─3208fd8a-7a17-11eb-35ce-4d6b141c1aff
# ╟─32116a92-7a17-11eb-228f-0713510d0348
# ╟─1af9b822-4239-4ac7-bc64-801a3461d9e1
# ╟─32277c3a-7a17-11eb-3763-af68dbb81465
# ╟─2c294933-1425-4e80-84f8-80fe73b2b03a
# ╟─a7363a47-83b6-458a-95dc-448f32d4ef4f
# ╟─d0b54b76-7852-11eb-2398-0911380fa090
# ╟─211911da-7a18-11eb-12d4-65b0dec4b8dc
# ╟─31b975b8-690d-41a0-b1a4-dcbf16a23517
# ╟─5f6cfe59-4d59-4ee6-a32c-712e2a67faa5
# ╠═5bb40ad6-7b33-11eb-0b31-63d5e47fa0e7
# ╟─5d956bd2-8472-47dc-909a-7930612e66de
# ╟─0b15c4a8-c4b3-4dc3-8aba-61222a48fd05
# ╠═7a88b8f0-6f22-4992-931b-54e7f50742f0
# ╠═d770f232-7864-11eb-0e9a-81528e359d39
# ╠═8168345f-67de-46ca-b9c9-a77ca838da74
# ╠═8767709c-478d-4fe5-ad6b-a280b9443460
# ╠═af13e090-7852-11eb-21ae-8b94f25f1a4f
# ╠═f59579f4-7163-415e-a5f3-18531084af45
# ╟─695e405c-786d-11eb-0a6e-bb776d9626ad
# ╟─01e40898-c1c8-481a-b149-9b1bebb00043
# ╟─1bb36c52-a171-4993-ac86-2250e1e87a01
# ╟─43101224-7ac5-11eb-104c-0323cf1813c5
# ╠═a0b3eec1-2ab5-4166-b27d-1e0968c1f06e
# ╠═792df1aa-7a23-11eb-2991-196336246c43
# ╠═8388305c-7a23-11eb-1588-79c3c6ce9db9
# ╟─7b618d71-2b56-42ba-9c3a-5840f4f0d481
# ╟─acbdbfa8-97bc-4194-81b9-4a203e7f8919
# ╟─b52ead96-7a2a-11eb-334f-e5e5ff5867e3
# ╠═b975680f-0b78-4178-861f-5da6d10327e4
# ╠═e0939f0e-d9f5-4ec6-937d-66367fb40fb6
# ╠═624f57db-7f07-4281-a547-d229b9a8413a
# ╠═8692573b-ae74-4f24-8bc3-57c7b85a7034
# ╟─064c14b0-73db-4bcf-9b64-a0e34c642f97
# ╟─16c2b86c-db2d-4408-a6ae-e698fdd495c7
# ╟─35a94847-a048-44fa-944c-33e6c397bf40
# ╟─88f59918-a0e0-4be4-be0a-06b86b90ad58
# ╠═5a5d4de6-7895-11eb-15c6-bda7a4342002
# ╠═b6560404-7b2d-11eb-21d7-a1e55609ebf7
# ╠═6f649efc-7b2d-11eb-1e80-53d84ef98c13
# ╟─20125640-79fd-11eb-1715-1d071cc6cf6c
# ╠═c26b5bb6-7984-11eb-18fe-2b6a524f5c85
# ╠═07a6ac8b-1663-4f07-9434-8915f7f529e1
# ╟─698a6dd0-7a0e-11eb-2766-1f0baa1317d2
# ╟─12740186-7b2f-11eb-35e4-01e6f9ffbb4d
# ╟─020cfb20-8228-11eb-2ee9-6de0fc7700b1
# ╠═ae92d828-7984-11eb-31c8-8b3f9a071c24
# ╟─58e38656-7b2e-11eb-3c70-25a919f9926a
# ╟─2b899624-798c-11eb-20c4-fd5523f7abff
# ╟─c1c74e70-7b2c-11eb-2f26-21f54ad00fb2
# ╟─aed5727a-744f-4b41-96a8-1c193bd42d68
# ╟─1332bc4c-8dfd-4022-8a40-413a85898b2a
# ╠═8522456a-823c-11eb-3cc1-fb720f1cc470
# ╟─0eb9b484-8270-40ed-ad5c-df342467e51a
# ╠═c18b54d5-3dc3-4977-841b-5a73215306d6
# ╟─1c4b19d2-7b30-11eb-007b-ab03052b22d2
# ╟─e302bd1c-7ab5-11eb-03f6-69dcbb817354
# ╟─442bcb3c-7940-11eb-18e5-d3158b74b1dc
