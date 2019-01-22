function instantiate_network(network::Type{N}, sys::PSY.PowerSystem; kwargs...) where N <: PM.AbstractActivePowerFormulationn

    d_netinjection_p =  JumpAffineExpressionArray(undef, length(sys.buses), sys.time_periods)

    ts_active = active_timeseries_netinjection(sys)

    netinjection = (var_active = d_netinjection_p, var_reactive = nothing, timeseries_active = ts_active, timeseries_reactive = nothing)

    return netinjection

end

function instantiate_network(network::Type{N}, sys::PSY.PowerSystem; kwargs...) where N <: PM.AbstractPowerFormulation

    d_netinjection_p =  JumpAffineExpressionArray(undef, length(sys.buses), sys.time_periods)

    ts_active = active_timeseries_netinjection(sys)

    d_netinjection_q =  JumpAffineExpressionArray(undef, length(sys.buses), sys.time_periods)

    ts_reactive = reactive_timeseries_netinjection(sys)

    netinjection = (var_active = d_netinjection_p, var_reactive = d_netinjection_q, timeseries_active = ts_active, timeseries_reactive = ts_reactive)

    return netinjection

end

function instantiate_network(network::Type{N}, sys::PSY.PowerSystem; kwargs...) where N <: CopperPlatePowerModel

    return instantiate_network(PM.AbstractActivePowerFormulationn, sys)

end

function instantiate_network(network::Type{N}, sys::PSY.PowerSystem; kwargs...) where N <: StandardPTDFModel

    return instantiate_network(PM.AbstractActivePowerFormulationn, sys)

end

#=
ps_model = PSI.canonical_model(Model(),
                              Dict{String, JuMP.Containers.DenseAxisArray{JuMP.VariableRef}}(),
                              Dict{String, JuMP.Containers.DenseAxisArray}(),
                              Dict{String, PSI.JumpAffineExpressionArray}("var_active" => PSI.JumpAffineExpressionArray(undef, 14, 24),
                                                                         "var_reactive" => PSI.JumpAffineExpressionArray(undef, 14, 24)),
                              Dict());
=#