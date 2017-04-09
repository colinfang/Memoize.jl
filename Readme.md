# Memoize.jl

[![Build Status](https://travis-ci.org/colinfang/Memoize.jl.svg?branch=master)](https://travis-ci.org/colinfang/Memoize.jl)

## Overview

This package provides basic support for type inference friendly generic function memoization. It allows to customize cache key from function arguments.

- Type inference friendly
- Cache invalidation
- Each method of a generic function has its own cache
- custom cache key
- Recursive functions

## Limitation

- It doesn't support keyword arguments or default arguments.
- It only support standard function definition with return type annotated.
- Parametric functions are not supported.
- It uses `Dict` for cache, not `ObjectIdDict`.


## Exposed Verbs

```julia
export @memoize, clear_cache, get_cache
```

## Usage

```julia
Pkg.clone("https://github.com/colinfang/Memoize.jl.git")

using Memoize

@memoize function fib(x::Int)::Int
   x <= 2 ? x : fib(x - 1) + fib(x - 2)
end

@memoize function fib(x::Float64, y)::Float64
   x + y
end

julia> fib(3), fib(1.0, 5)
(3, 6.0)

julia> @time fib(100)
0.000073 seconds (199 allocations: 14.166 KiB)
juila> @time fib(100)
0.000005 seconds (5 allocations: 176 bytes)

julia> get_cache(fib)
Dict{Tuple,Dict} with 2 entries:
  (Float64, Any) => Dict{Any,Float64}(Pair{Any,Float64}((1.0, 5), 6.0))
  (Int64,)       => Dict{Any,Int64}(Pair{Any,Int64}(68, 117669030460994),Pair{A…

julia> clear_cache(fib)
julia> get_cache(fib)
Dict{Tuple,Dict} with 2 entries:
  (Float64, Any) => Dict{Any,Float64}()
  (Int64,)       => Dict{Any,Int64}()

julia> @time fib(100)
0.000027 seconds (5 allocations: 176 bytes)

julia> @code_warntype fib(3)
Variables:
  #self#::#fib
  x::Int64
  unmemoized::#unmemoized#1{Int64}
  key::Int64
  cache::Dict{Any,Int64}

Body:
  begin
      unmemoized::#unmemoized#1{Int64} = $(Expr(:new, #unmemoized#1{Int64}, :(x))) # line 153:
      cache::Dict{Any,Int64} = Main.##cache#687 # line 154:
      SSAValue(1) = $(Expr(:invoke, MethodInstance for get!(::#unmemoized#1{Int64}, ::Dict{Any,Int64}, ::Int64), :(Memoize.get!), :(unmemoized), :(cache), :(x)))
      return SSAValue(1)
  end::Int64


# Assume `y` doesn't affect the result.
function Memoize.make_key(::typeof(fib), x, y)
   x
end

julia> fib(1.0, 5)
6.0
julia> fib(1.0, 6)
6.0


```