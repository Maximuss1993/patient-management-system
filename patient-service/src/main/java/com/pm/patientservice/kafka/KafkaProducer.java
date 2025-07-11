package com.pm.patientservice.kafka;

import com.pm.patientservice.model.Patient;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import patient.events.PatientEvent;

@Slf4j
@Service
public class KafkaProducer {

  private final KafkaTemplate<String, byte[]> kafkaTemplate;
  private static final String PATIENT_TOPIC = "patient";

  public KafkaProducer(KafkaTemplate<String, byte[]> kafkaTemplate) {
    this.kafkaTemplate = kafkaTemplate;
  }

  public void sendEvent(Patient patient) {
    PatientEvent event = PatientEvent.newBuilder()
        .setPatientId(patient.getId().toString())
        .setName(patient.getName())
        .setEmail(patient.getEmail())
        .setEventType("PATIENT_CREATED")
        .build();

    try {
      kafkaTemplate.send(PATIENT_TOPIC, event.toByteArray());
    } catch (Exception ex) {
      log.error("Error sending PatientCreated event for patientId {}: {}",
          patient.getId(), ex.getMessage(), ex);

    }
  }

}