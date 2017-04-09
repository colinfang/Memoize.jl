module Memoize

export @memoize, clear_cache, get_cache

function make_key(::Function, args...)
    args
end

function make_key(::Function, x)
    x
end

# function memoize{T}(f, ::Type{T})
#     cache = Dict{Any, T}()
#     function g(args...)::T
#         key = make_key(args...)
#         get!(cache, key) do
#             f(args...)
#         end
#     end
#     g
# end

# const fib = memoize(x::Int -> begin
#     if x == 2
#         return 2
#     end
#     if x == 1
#         return 1
#     end
#     fib(x - 1) + fib(x - 2)
# end, Int)

# @code_warntype fib(3)
# @code_warntype fib.f(3)


type FunctionAst
    func_name::Symbol
    parameters::Vector{Any}
    return_type::Any
    body::Vector{Any}
end


function decompose_parameter(x::Symbol)
    x, :Any
end

function decompose_parameter(x::Expr)
    @assert x.head == :(::)
    name, variable_type = x.args
end

function parameter_names_and_types(ast::FunctionAst)
    if isempty(ast.parameters)
        return (), ()
    else
        parameter_names, parameter_types = zip(decompose_parameter.(ast.parameters)...)
        return parameter_names, parameter_types
    end
end

function FunctionAst(ast)
    @assert ast.head == :function
    header, body = ast.args
    # Has `return_type`.
    @assert header.head == :(::)
    header_token, return_type = header.args
    @assert header_token.head == :call
    func_name = header_token.args[1]
    parameters = header_token.args[2:end]
    @assert body.head == :block

    FunctionAst(func_name, parameters, return_type, body.args)
end

function compose(x::FunctionAst)
    body = Expr(:block, x.body...)
    header_token = Expr(:call, x.func_name, x.parameters...)
    header = Expr(:(::), header_token, x.return_type)
    full = Expr(:function, header, body)
end


# ast = (quote
#     function f(x::Int, y, z)::Int
#         t1()
#         t2()
#     end
# end).args[2]

# Meta.show_sexpr(ast)
# compose(FunctionAst(ast))
# eval(compose(FunctionAst(ast)))

# ast = (quote
#     function f()::Int
#         t1()
#         t2()
#     end
# end).args[2]

# Meta.show_sexpr(ast)
# compose(FunctionAst(ast))
# eval(compose(FunctionAst(ast)))


const CACHE = Dict{Tuple{Module, Symbol}, Dict}()

function clear_cache(m::Module, func_name::Symbol)
    for cache in values(CACHE[m, func_name])
        empty!(cache)
    end
end

clear_cache(f::Function) = clear_cache(typeof(f).name.module, Base.function_name(f))


function get_cache(m::Module, func_name::Symbol)
    CACHE[m, func_name]
end

get_cache(f::Function) = get_cache(typeof(f).name.module, Base.function_name(f))


macro memoize(f)
    func_ast = FunctionAst(f)

    return_type = esc(func_ast.return_type)
    func_name = esc(func_ast.func_name)
    parameters = esc.(func_ast.parameters)
    pn, pt = parameter_names_and_types(func_ast)
    parameter_names = esc.(pn)
    parameter_types = esc.(pt)

    key = esc(:key)
    cache = esc(:cache)
    func_cache = get!(Dict{Tuple, Dict}, CACHE, (current_module(), func_ast.func_name))
    global_cache = gensym(:cache)

    func_ast.func_name = :unmemoized
    func_ast.parameters = []
    unmemoized = esc(compose(func_ast))

    quote
        pt = ($(parameter_types...),)
        const global $global_cache = get!(Dict{Any, $return_type}, $func_cache, pt)

        function $func_name($(parameters...))::$return_type
            $unmemoized
            $key = make_key($func_name, $(parameter_names...))
            $cache = $(esc(global_cache))
            get!($(esc(:unmemoized)), $cache, $key)
        end
    end
end





end

