
@testset "Test logger" begin
    lg = LiveLogger()
    
    @test lg.step == 1

    next_step!(lg)

    @test lg.step == 2

end
