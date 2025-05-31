package com.pm.patientservice.service;

import com.pm.patientservice.dto.PatientRequestDTO;
import com.pm.patientservice.dto.PatientResponseDTO;
import com.pm.patientservice.exception.EmailAlreadyExistsException;
import com.pm.patientservice.exception.PatientNotFoundException;
import com.pm.patientservice.mapper.PatientMapper;
import com.pm.patientservice.model.Patient;
import com.pm.patientservice.repository.PatientRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
public class PatientService {

  private final PatientRepository patientRepository;
  private final PatientMapper patientMapper = PatientMapper.INSTANCE;

  public PatientService(PatientRepository patientRepository) {
    this.patientRepository = patientRepository;
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
    return patientMapper.toPatientResponseDTO(savedPatient);
  }

  public PatientResponseDTO updatePatient(UUID id, PatientRequestDTO requestDTO) {

    Patient patient = patientRepository.findById(id).orElseThrow(() ->
        new PatientNotFoundException("Patient not found with ID: " + id));

    if(patientRepository.existsByEmailAndIdNot(requestDTO.email(), id)) {
      throw new EmailAlreadyExistsException(
          "A patient with this email already exists: " +
              requestDTO.email());
    }

    patient.setName(requestDTO.name());
    patient.setAddress(requestDTO.address());
    patient.setEmail(requestDTO.email());
    patient.setDateOfBirth(LocalDate.parse(requestDTO.dateOfBirth()));

    return patientMapper.toPatientResponseDTO(patient);
  }

  public void deletePatient(UUID id) {
    patientRepository.deleteById(id);
  }

}
