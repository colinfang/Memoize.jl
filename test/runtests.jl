using Base.Test
using Memoize


@memoize function fib(x::Int)::Int
   x <= 2 ? x : fib(x - 1) + fib(x - 2)
end

@memoize function fib(x::Float64, y)::Float64
   x + y
end

@test fib(3) == 3
@test fib(1.0, 5) == 6
@test Base.return_types(fib, (Int,)) == [Int]

clear_cache(fib)

function Memoize.make_key(::typeof(fib), x, y)
   x
end

@test fib(1.0, 5) == 6
@test fib(1.0, 6) == 6