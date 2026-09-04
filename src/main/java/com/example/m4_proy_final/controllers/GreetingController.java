package com.example.m4_proy_final.controllers;

import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class GreetingController {
	@Value("${server.port:8080}")
	private String port;

	@Value("${APP_INSTANCE:unknown}")
	private String instance;

	@GetMapping("/hello")
	public String hello() {
		return "Hola desde M4 Proy Final";
	}

	@GetMapping("/instance")
	public Map<String, String> instance() {
		return Map.of("instance",  instance, "port", port);
	}

	@GetMapping("/version")
	public String version() {
		return "m4-proy-final v1.1.0";
	}

	@GetMapping("/random-animal")
	public String randomWord() {
		return "cat";
	}
}
