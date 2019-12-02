abstract type AbstractReservesFormulation <: AbstractServiceFormulation end
struct RangeReserve <: AbstractReservesFormulation end
############################### Reserve Variables` #########################################
"""
This function add the variables for reserves to the model
"""
function activeservice_variables!(psi_container::PSIContainer,
                                  service::SR,
                                  devices::Vector{<:PSY.Device}) where SR<:PSY.Reserve
    add_variable(psi_container,
                 devices,
                 Symbol("$(PSY.get_name(service))_$SR"),
                 false;
                 ub_value = d -> d.tech.activepowerlimits.max,
                 lb_value = d -> 0 )
    return
end

################################## Reserve Requirement Constraint ##########################
# This function can be generalized later for any constraint of type Sum(req_var) >= requirement,
# it will only need to be specific to the names and get forecast string.
function service_requirement_constraint!(psi_container::PSIContainer,
                                         service::SR) where {SR<:PSY.Reserve}
    time_steps = model_time_steps(psi_container)
    parameters = model_has_parameters(psi_container)
    forecast = model_uses_forecasts(psi_container)
    initial_time = model_initial_time(psi_container)
    reserve_variable = get_variable(psi_container, Symbol("$(PSY.get_name(service))_$SR"))
    constraint_name = Symbol(PSY.get_name(service), "_requirement_$SR")
    constraint = add_cons_container!(psi_container, constraint_name, time_steps)
    requirement = PSY.get_requirement(service)
    if forecast
        ts_vector = TS.values(PSY.get_data(PSY.get_forecast(PSY.Deterministic,
                                                            service,
                                                            initial_time,
                                                            "get_requirement")))
    else
        ts_vector = ones(time_steps[end])
    end
    if parameters
        param = include_parameters(psi_container, ts_vector,
                                   UpdateRef{SR}("get_requirement"), time_steps)
        for t in time_steps
            constraint[t] = JuMP.@constraint(psi_container.JuMPmodel,
                                         sum(reserve_variable[:,t]) >= param[t]*requirement)
        end
    else
        for t in time_steps
            constraint[t] = JuMP.@constraint(psi_container.JuMPmodel,
                                    sum(reserve_variable[:,t]) >= ts_vector[t]*requirement)
        end
    end
    return
end

function device_model_modify!(devices_template::Dict{Symbol, DeviceModel},
                              service_model::ServiceModel{<:PSY.Reserve, RangeReserve},
                              contributing_devices::Vector{<:PSY.Device})
    device_types = unique(typeof.(contributing_devices))
    for dt in device_types
        for (k, v) in devices_template
            v.device_type != dt && continue
            service_model in v.services && continue
            push!(v.services, service_model)
        end
    end

    return
end

function include_service!(constraint_data::DeviceRange,
                           index::Int64,
                           services::Vector{PSY.VariableReserve{PSY.ReserveUp}},
                           ::ServiceModel{PSY.VariableReserve{PSY.ReserveUp}, <:AbstractReservesFormulation})
        services_ub = Vector{Symbol}(undef, length(services))
        for (ix, service) in enumerate(services)
            SR = typeof(service) #To be removed later and subtitute with argument
            services_ub[ix] = Symbol("$(PSY.get_name(service))_$SR")
        end
        constraint_data.additional_terms_ub[index] = services_ub
    return
end

function include_service!(constraint_data::DeviceRange,
                           index::Int64,
                           services::Vector{PSY.VariableReserve{PSY.ReserveDown}},
                           ::ServiceModel{PSY.VariableReserve{PSY.ReserveDown}, <:AbstractReservesFormulation})
        services_lb = Vector{Symbol}(undef, length(services))
        for (ix, service) in enumerate(services)
            SR = typeof(service) #To be removed later and subtitute with argument
            services_ub[ix] = Symbol("$(PSY.get_name(service))_$SR")
        end
        constraint_data.additional_terms_lb[index] = services_lb
    return
end
