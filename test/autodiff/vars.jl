using NiLang, NiLang.AD
using Test

@testset "gvar" begin
    g1 = GVar(0.0)
    @test (~GVar)(g1) === 0.0
    @assign (g1 |> grad) 0.5
    @test g1 === GVar(0.0, 0.5)
    @test_throws InvertibilityError (~GVar)(g1)
    @test !almost_same(GVar(0.0), GVar(0.0, 1.0))
    @test zero(GVar(3.0, 2.0)) == GVar(0.0)
    @test one(GVar(3.0, 2.0)) == GVar(1.0)
    @test iszero(GVar(0.0, 2.0))
    @test zero(GVar(2, AutoBcast([1, 0, 0]))) == GVar(0, AutoBcast([0, 0, 0]))
    @test GVar(true) == true
end


@testset "assign" begin
    arg = (1,2,GVar(3.0))
    @assign (arg |> tget(3)).g 4.0
    @test arg[3].g == 4.0
    gv = GVar(1.0, GVar(0.0))
    @test gv.g.g === 0.0
    @assign gv.g.g 7.0
    @test gv.g.g === 7.0
    gv = GVar(1.0, GVar(0.0))
    @assign gv |> grad |> grad 0.0
    @test gv.g.g === 0.0
    args = (GVar(0.0, 1.0),)
    @assign (args |> tget(1) |> grad) 0.0
    @test args[1].g == 0.0
    arr = [1.0]
    arr0 = arr
    @assign arr[] 0.0
    @test arr[] == 0.0
    @test arr === arr0
end

@testset "assign tuple" begin
    x = 0.3
    @instr for i=1:length(x) GVar(x) end
    @test x === GVar(0.3)
end


@testset "assign bcast func" begin
    # vector bcast
    x = [GVar(0.1, 0.1), GVar(0.2, 0.2)]
    res = [1.0, 2.0]
    @assign (x .|> value) res
    @test x == [GVar(1.0, 0.1), GVar(2.0, 0.2)]

    # tuple bcast
    x = (GVar(0.1, 0.1), GVar(0.2, 0.2))
    res = (1.0, 2.0)
    @assign (x .|> value) res
    @test x == (GVar(1.0, 0.1), GVar(2.0, 0.2))
end

@testset "GVar over general type" begin
    struct ABC{T1, T2}
       a::T1
       b::T1
       c::T2
    end
    x = ABC(1, 2, 3.0)
    @test GVar(x) == ABC(1, 2, GVar(3.0))
    @test (~GVar)(ABC(1, 2, GVar(3.0))) == x
end
