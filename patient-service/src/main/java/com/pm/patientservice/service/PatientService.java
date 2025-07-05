package com.pm.patientservice.service;

import com.pm.patientservice.dto.PatientRequestDTO;
import com.pm.patientservice.dto.PatientResponseDTO;
import com.pm.patientservice.exception.EmailAlreadyExistsException;
import com.pm.patientservice.exception.PatientNotFoundException;
import com.pm.patientservice.grpc.BillingServiceGrpcClient;
import com.pm.patientservice.kafka.KafkaProducer;
import com.pm.patientservice.mapper.PatientMapper;
import com.pm.patientservice.model.Patient;
import com.pm.patientservice.repository.PatientRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
@Slf4j
public class PatientService {

  private final PatientRepository patientRepository;
  private final PatientMapper patientMapper = PatientMapper.INSTANCE;
  private final BillingServiceGrpcClient billingServiceGrpcClient;
  private final KafkaProducer kafkaProducer;

  public PatientService(PatientRepository patientRepository,
                        BillingServiceGrpcClient billingServiceGrpcClient, KafkaProducer kafkaProducer) {
    this.patientRepository = patientRepository;
    this.billingServiceGrpcClient = billingServiceGrpcClient;
    this.kafkaProducer = kafkaProducer;
  }

  public List<PatientResponseDTO> getPatients() {
    return patientRepository
            .findAll()
            .stream()
            .map(patientMapper::toPatientResponseDTO)
            .toList();
  }

  public PatientResponseDTO createPatient(PatientRequestDTO requestDTO) {

    if(patientRepository.existsByEmail(requestDTO.email())) {
      throw new EmailAlreadyExistsException(
              "A patient with this email already exists: " +
                      requestDTO.email());
    }

    Patient newPatient = patientMapper.toPatient(requestDTO);
    Patient savedPatient = patientRepository.save(newPatient);

    billingServiceGrpcClient.createBillingAccount(
            String.valueOf(savedPatient.getId()),
            savedPatient.getName(),
            savedPatient.getEmail()
    );

    kafkaProducer.sendEvent(savedPatient);

    return patientMapper.toPatientResponseDTO(savedPatient);
  }

  public PatientResponseDTO updatePatient(UUID id, PatientRequestDTO requestDTO) {
    Patient patient = patientRepository.findById(id).orElseThrow(() ->
            new PatientNotFoundException("Patient not found with ID: " + id));

    if (patientRepository.existsByEmailAndIdNot(requestDTO.email(), id)) {
      throw new EmailAlreadyExistsException(
              "A patient with this email already exists: " + requestDTO.email());
    }

    patient.setName(requestDTO.name());
    patient.setAddress(requestDTO.address());
    patient.setEmail(requestDTO.email());
    patient.setDateOfBirth(LocalDate.parse(requestDTO.dateOfBirth()));

    Patient updatedPatient = patientRepository.save(patient);
    log.info("Updated patient with ID {}", id);

    return patientMapper.toPatientResponseDTO(updatedPatient);
  }

  public void deletePatient(UUID id) {
    patientRepository.deleteById(id);
  }

}