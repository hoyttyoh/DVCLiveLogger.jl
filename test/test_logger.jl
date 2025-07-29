
using Mocking

@testset "Test logger init" begin

    Mocking.activate()

    p1 = @patch DVCLiveLogger.make_dvcyaml(x::LiveLogger)=nothing
    p2 = @patch DVCLiveLogger.make_summary(x::LiveLogger)=nothing
    
    apply([p1,p2]) do
        lg = LiveLogger()

        @test lg.step == 1

        next_step!(lg)

        @test lg.step == 2

        @test lg.resume == false
        
    end



end
