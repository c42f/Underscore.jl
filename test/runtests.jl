using Underscores
using Test

@testset "Underscores Examples" begin
    @test [1,"a",2.0] == @_ map(_, [1,"a",2.0])

    strs = ["ab", "ca", "ad"]
    @test [true, false, true] == @_ map(startswith(_, "a"), strs)

    data = [(x="a", y=1),
            (x="b", y=2),
            (x="c", y=3)]

    @test data[1:1] == @_ filter(startswith(_.x, "a"), data)
    @test data[2:3] == @_ filter(_.y >= 2, data)

    # Multiple args
    @test [1,3] == @_ map(_+1-_, [1,2], [1,0])

    # Use with piping and lazy versions of map and filter
    Filter(f) = x->filter(f,x)
    Map(f) = x->map(f,x)

    @test [1] == @_ data |>
                    Filter(startswith(_.x, "a")) |>
                    Map(_.y)

    @test [1] == @_(Map(_.y) ∘ Filter(startswith(_.x, "a")))(data)
end

@testset "Underscores lowering" begin
    cleanup! = Base.remove_linenums!
    lower(ex) = cleanup!(Underscores.lower_underscores(ex))

    @test lower(:(f(_))) == cleanup!(:(f((_1,)->_1)))
    @test lower(:(f(g(h(_))))) == cleanup!(:(f(((_1,)->g(h(_1))))))

    # Multiple arguments
    @test lower(:(f(_,a))) == cleanup!(:(f(((_1,)->_1), a)))
    @test lower(:(f(a,_))) == cleanup!(:(f(a, ((_1,)->_1))))
    @test lower(:(f(_,_))) == cleanup!(:(f(((_1,)->_1), ((_1,)->_1))))
    @test lower(:(f(_+_))) == cleanup!(:(f(((_1,_2)->_1+_2))))

    # Numbered arguments
    @test lower(:(f(_1))) == cleanup!(:(f((_1,)->_1)))
    @test lower(:(f(_2))) == cleanup!(:(f((_1,_2)->_2)))
    @test lower(:(f(_2+_1))) == cleanup!(:(f((_1,_2)->_2+_1)))

    # Can't mix numbered and non-numbered placeholders
    @test_throws ArgumentError lower(:(f(_+_1)))

    # piping and composition
    @test lower(:(f(_) |> g(_) |> h(_))) ==
          cleanup!(:(f((_1,)->_1) |> g((_1,)->_1) |> h((_1,)->_1)))
    @test lower(:(f(_) ∘ g(_) ∘ h(_))) ==
          cleanup!(:(f((_1,)->_1) ∘ g((_1,)->_1) ∘ h((_1,)->_1)))
    @test lower(:(f(_) <| g(_) <| h(_))) ==
          cleanup!(:(f((_1,)->_1) <| g((_1,)->_1) <| h((_1,)->_1)))
end

