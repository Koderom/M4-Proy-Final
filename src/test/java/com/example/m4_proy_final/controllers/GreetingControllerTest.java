package com.example.m4_proy_final.controllers;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class GreetingControllerTest {

	@Autowired
	private MockMvc mockMvc;

	@Test
	void helloReturnsGreeting() throws Exception {
		mockMvc.perform(get("/api/hello"))
			.andExpect(status().isOk())
			.andExpect(content().string("Hola desde M4 Proy Final"));
	}

	@Test
	void instanceReturnsGreenOnDefaultPort() throws Exception {
		mockMvc.perform(get("/api/instance"))
			.andExpect(status().isOk())
			.andExpect(content().json("{\"instance\":\"unknown\",\"port\":\"8081\"}"));
	}

	@Test
	void versionReturnsAppVersion() throws Exception {
		mockMvc.perform(get("/api/version"))
			.andExpect(status().isOk())
			.andExpect(content().string("m4-proy-final v1.1.0"));
	}

	@Test
	void retunRandomWord() throws Exception {
		mockMvc.perform(get("/api/random-animal"))
				.andExpect(status().isOk())
				.andExpect(content().string("cat"));
	}

}
