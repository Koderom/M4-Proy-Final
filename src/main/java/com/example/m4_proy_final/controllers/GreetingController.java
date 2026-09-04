package com.example.m4_proy_final.controllers;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class GreetingController {

	@GetMapping("/hello")
	public String hello() {
		return "Hola desde M4 Proy Final";
	}

}
