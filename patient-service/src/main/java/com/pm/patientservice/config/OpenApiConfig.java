package com.pm.patientservice.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.info.Contact;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.servers.Server;

@OpenAPIDefinition(
    info = @Info(
        contact = @Contact(
            name = "Marko Popov",
            email = "markopopov1993@gmail.com",
            url = "https://github.com/Maximuss1993"
        ),
        description = "OpenApi documentation for Patient Service",
        title = "OpenApi specification - Marko Popov",
        version = "1.0"
    ),
    servers = {
        @Server(
            description = "Local ENV",
            url = "http://localhost:4000"
        )
    })
public class OpenApiConfig {
}
