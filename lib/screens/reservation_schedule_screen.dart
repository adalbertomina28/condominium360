import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/custom_button.dart';

class ReservationScheduleScreen extends StatefulWidget {
  const ReservationScheduleScreen({Key? key}) : super(key: key);

  @override
  _ReservationScheduleScreenState createState() => _ReservationScheduleScreenState();
}

class _ReservationScheduleScreenState extends State<ReservationScheduleScreen> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CommonArea? _selectedArea;
  List<CommonArea> _commonAreas = [];
  List<Reservation> _existingReservations = [];
  List<AreaSchedule> _availableSchedules = [];
  AreaCapacity? _areaCapacity;
  AreaSchedule? _selectedSchedule;
  int _selectedPeople = 1;
  bool _isLoading = true;
  String? _errorMessage;
  bool _userHasReservationToday = false;

  @override
  void initState() {
    super.initState();
    // Inicializar datos de localización para el formato de fecha en español
    initializeDateFormatting('es');
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Cargar áreas comunes
      final commonAreaService = CommonAreaService(SupabaseService.client);
      final authService = AuthService(SupabaseService.client);
      final user = await authService.getCurrentUser();

      if (user == null || user.unitId == null) {
        setState(() {
          _errorMessage =
              'Debes estar asociado a una unidad para hacer reservas';
        });
        return;
      }

      // Obtener el condominio de la unidad
      final unitService = UnitService(SupabaseService.client);
      final unit = await unitService.getUnitById(user.unitId!);

      // Cargar áreas comunes del condominio
      _commonAreas = await commonAreaService
          .getCommonAreasByCondominiumId(unit.condominiumId);

      if (_commonAreas.isNotEmpty) {
        _selectedArea = _commonAreas.first;
        await _loadReservations();
        await _loadAreaCapacity();
        await _loadAvailableSchedules();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar datos: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadReservations() async {
    if (_selectedArea == null) return;

    try {
      final reservationService = ReservationService(SupabaseService.client);

      // Calcular rango de fechas para cargar reservas (mes actual)
      final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      _existingReservations = await reservationService
          .getReservationsByCommonAreaId(_selectedArea!.id);

      // Filtrar por el rango de fechas
      _existingReservations = _existingReservations.where((reservation) {
        return reservation.startDate.isAfter(firstDay) &&
            reservation.startDate.isBefore(lastDay);
      }).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar reservas: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadAreaCapacity() async {
    if (_selectedArea == null) return;

    try {
      final areaScheduleService = AreaScheduleService(SupabaseService.client);
      _areaCapacity = await areaScheduleService.getAreaCapacity(_selectedArea!.id);
      
      // Si no hay capacidad definida, establecemos un valor predeterminado
      if (_areaCapacity == null) {
        _areaCapacity = AreaCapacity(
          id: 0,
          areaId: _selectedArea!.id,
          maxPeople: 10, // Valor predeterminado
        );
      }

      // Asegurarnos de que el número de personas seleccionado no exceda la capacidad máxima
      if (_selectedPeople > _areaCapacity!.maxPeople) {
        _selectedPeople = 1;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar capacidad del área: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadAvailableSchedules() async {
    if (_selectedArea == null || _selectedDay == null) return;

    try {
      // Verificar si el usuario ya tiene una reserva para este día y área
      final authService = AuthService(SupabaseService.client);
      final user = await authService.getCurrentUser();
      
      if (user != null && user.unitId != null) {
        _userHasReservationToday = await _userHasReservationForDayAndArea(
          user.unitId!,
          _selectedArea!.id,
          _selectedDay!,
        );
      } else {
        _userHasReservationToday = false;
      }
      
      // Si el usuario ya tiene una reserva, no cargamos los horarios disponibles
      if (_userHasReservationToday) {
        _availableSchedules = [];
        _selectedSchedule = null;
        return;
      }
      
      final areaScheduleService = AreaScheduleService(SupabaseService.client);
      
      // Obtener el nombre del día de la semana en español
      final weekday = _getWeekdayName(_selectedDay!.weekday);
      
      // Cargar horarios disponibles para el día seleccionado
      _availableSchedules = await areaScheduleService.getSchedulesForWeekday(
        _selectedArea!.id,
        weekday,
      );

      // Limpiar selección previa si ya no está disponible
      if (_selectedSchedule != null && 
          !_availableSchedules.any((schedule) => schedule.id == _selectedSchedule!.id)) {
        _selectedSchedule = null;
      }

      // Si no hay horario seleccionado y hay horarios disponibles, seleccionamos el primero
      if (_selectedSchedule == null && _availableSchedules.isNotEmpty) {
        _selectedSchedule = _availableSchedules.first;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar horarios disponibles: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Convertir número de día de la semana (1-7) a nombre en español
  String _getWeekdayName(int weekday) {
    const Map<int, String> weekdayMap = {
      1: 'lunes',
      2: 'martes',
      3: 'miércoles',
      4: 'jueves',
      5: 'viernes',
      6: 'sábado',
      7: 'domingo',
    };
    return weekdayMap[weekday] ?? 'lunes';
  }

  // Verificar si un horario ya está reservado
  bool _isScheduleReserved(AreaSchedule schedule) {
    if (_selectedDay == null) return false;

    // Crear DateTime para la hora de inicio y fin del horario en el día seleccionado
    final scheduleStart = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      schedule.startTime.hour,
      schedule.startTime.minute,
    );
    
    final scheduleEnd = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      schedule.endTime.hour,
      schedule.endTime.minute,
    );

    // Verificar si hay alguna reserva que se solape con este horario
    return _existingReservations.any((reservation) {
      return reservation.commonAreaId == _selectedArea!.id &&
             reservation.startDate.day == _selectedDay!.day &&
             reservation.startDate.month == _selectedDay!.month &&
             reservation.startDate.year == _selectedDay!.year &&
             ((reservation.startDate.isBefore(scheduleEnd) || 
               reservation.startDate.isAtSameMomentAs(scheduleEnd)) &&
              (reservation.endDate.isAfter(scheduleStart) || 
               reservation.endDate.isAtSameMomentAs(scheduleStart)));
    });
  }
  
  // Verificar si el usuario ya tiene una reserva para este día y área
  Future<bool> _userHasReservationForDayAndArea(int unitId, int areaId, DateTime date) async {
    try {
      final reservationService = ReservationService(SupabaseService.client);
      
      // Obtener todas las reservas del usuario para esta área
      final userReservations = await reservationService.getReservationsByUnitId(unitId);
      
      // Filtrar por área y fecha
      return userReservations.any((reservation) {
        return reservation.commonAreaId == areaId &&
               reservation.startDate.day == date.day &&
               reservation.startDate.month == date.month &&
               reservation.startDate.year == date.year;
      });
    } catch (e) {
      print('Error al verificar reservas del usuario: $e');
      return false;
    }
  }

  Future<void> _createReservation() async {
    if (_selectedArea == null || _selectedDay == null || _selectedSchedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un área, fecha y horario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService(SupabaseService.client);
      final reservationService = ReservationService(SupabaseService.client);
      final user = await authService.getCurrentUser();

      if (user == null || user.unitId == null) {
        throw Exception('Debes estar asociado a una unidad para hacer reservas');
      }

      // Crear DateTime para la hora de inicio y fin del horario en el día seleccionado
      final startDate = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        _selectedSchedule!.startTime.hour,
        _selectedSchedule!.startTime.minute,
      );
      
      final endDate = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        _selectedSchedule!.endTime.hour,
        _selectedSchedule!.endTime.minute,
      );

      // Verificar si el horario ya está reservado
      if (_isScheduleReserved(_selectedSchedule!)) {
        throw Exception('Este horario ya está reservado');
      }
      
      // Verificar si el usuario ya tiene una reserva para este día y área
      final hasReservation = await _userHasReservationForDayAndArea(
        user.unitId!,
        _selectedArea!.id,
        _selectedDay!,
      );
      
      if (hasReservation) {
        throw Exception('Ya tienes una reserva para esta área en esta fecha. Solo se permite una reserva por día por área.');
      }

      // Crear la reserva
      final reservation = Reservation(
        id: 0, // ID será asignado por la base de datos
        unitId: user.unitId!,
        commonAreaId: _selectedArea!.id,
        startDate: startDate,
        endDate: endDate,
        status: 'pendiente',
        people: _selectedPeople,
      );

      await reservationService.createReservation(reservation);

      // Recargar reservas
      await _loadReservations();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva creada con éxito'),
          backgroundColor: Colors.green,
        ),
      );

      // Limpiar selección
      setState(() {
        _selectedSchedule = null;
        _selectedPeople = 1;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear reserva: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Reservation> _getReservationsForDay(DateTime day) {
    return _existingReservations.where((reservation) {
      return reservation.startDate.year == day.year &&
          reservation.startDate.month == day.month &&
          reservation.startDate.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservar Área Común'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'Reintentar',
                          icon: Icons.refresh,
                          onPressed: _loadData,
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selección de área común
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selecciona un área común',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<CommonArea>(
                                value: _selectedArea,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                items: _commonAreas.map((area) {
                                  return DropdownMenuItem<CommonArea>(
                                    value: area,
                                    child: Text(area.name),
                                  );
                                }).toList(),
                                onChanged: (value) async {
                                  // Mostrar indicador de carga
                                  setState(() {
                                    _isLoading = true;
                                    _selectedArea = value;
                                    _selectedSchedule = null;
                                    _userHasReservationToday = false; // Reiniciar el estado
                                  });
                                  
                                  // Cargar datos necesarios
                                  await _loadReservations();
                                  await _loadAreaCapacity();
                                  await _loadAvailableSchedules();
                                  
                                  // Actualizar la UI
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                },
                              ),
                              if (_areaCapacity != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Capacidad máxima: ${_areaCapacity!.maxPeople} personas',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Calendario
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selecciona una fecha',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TableCalendar(
                                firstDay: DateTime.now(),
                                lastDay: DateTime.now().add(const Duration(days: 90)),
                                focusedDay: _focusedDay,
                                calendarFormat: _calendarFormat,
                                availableCalendarFormats: const {
                                  CalendarFormat.month: 'Mes',
                                },
                                selectedDayPredicate: (day) {
                                  return isSameDay(_selectedDay, day);
                                },
                                onDaySelected: (selectedDay, focusedDay) async {
                                  // Mostrar indicador de carga
                                  setState(() {
                                    _isLoading = true;
                                    _selectedDay = selectedDay;
                                    _focusedDay = focusedDay;
                                    _selectedSchedule = null;
                                    _userHasReservationToday = false; // Reiniciar el estado
                                  });
                                  
                                  // Esperar a que se carguen los horarios disponibles
                                  await _loadAvailableSchedules();
                                  
                                  // Actualizar la UI
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                },
                                eventLoader: (day) {
                                  return _getReservationsForDay(day);
                                },
                                calendarStyle: CalendarStyle(
                                  markersMaxCount: 3,
                                  markerDecoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  todayDecoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  selectedDecoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Horarios disponibles
                      if (_selectedDay != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Horarios disponibles para el ${DateFormat('EEEE d MMMM, yyyy', 'es').format(_selectedDay!)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_userHasReservationToday)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'Ya tienes una reserva para esta área en esta fecha. Solo se permite una reserva por día por área.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )
                                else if (_availableSchedules.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'No hay horarios disponibles para este día',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _availableSchedules.map((schedule) {
                                      final isReserved = _isScheduleReserved(schedule);
                                      return ChoiceChip(
                                        label: Text(schedule.timeRange),
                                        selected: _selectedSchedule?.id == schedule.id,
                                        onSelected: isReserved
                                            ? null
                                            : (selected) {
                                                if (selected) {
                                                  setState(() {
                                                    _selectedSchedule = schedule;
                                                  });
                                                }
                                              },
                                        backgroundColor: Colors.grey.shade200,
                                        selectedColor: Colors.blue.shade100,
                                        disabledColor: Colors.red.shade100,
                                        labelStyle: TextStyle(
                                          color: isReserved
                                              ? Colors.red.shade800
                                              : _selectedSchedule?.id == schedule.id
                                                  ? Colors.blue.shade800
                                                  : Colors.black,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Número de personas
                      if (_selectedSchedule != null && _areaCapacity != null && !_userHasReservationToday) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Número de personas',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: _selectedPeople > 1
                                          ? () {
                                              setState(() {
                                                _selectedPeople--;
                                              });
                                            }
                                          : null,
                                    ),
                                    Expanded(
                                      child: Text(
                                        '$_selectedPeople',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: _selectedPeople < _areaCapacity!.maxPeople
                                          ? () {
                                              setState(() {
                                                _selectedPeople++;
                                              });
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Capacidad máxima: ${_areaCapacity!.maxPeople} personas',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Botón de reserva
                      if (_selectedSchedule != null && !_userHasReservationToday)
                        CustomButton(
                          text: 'Crear Reserva',
                          icon: Icons.check,
                          onPressed: _createReservation,
                          isLoading: _isLoading,
                        ),

                      const SizedBox(height: 24),

                      // Reservas existentes para el día seleccionado
                      if (_selectedDay != null) ...[
                        const Text(
                          'Mis reservas para este día',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._getReservationsForDay(_selectedDay!).map((reservation) {
                          final CommonArea? area = _commonAreas.firstWhere(
                            (area) => area.id == reservation.commonAreaId,
                            orElse: () => _commonAreas.first,
                          );
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          area?.name ?? 'Área común',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${DateFormat('HH:mm').format(reservation.startDate)} - ${DateFormat('HH:mm').format(reservation.endDate)}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'Personas: ${reservation.people}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: reservation.status == 'aprobada'
                                          ? Colors.green.shade100
                                          : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      reservation.status == 'aprobada'
                                          ? 'Aprobada'
                                          : 'Pendiente',
                                      style: TextStyle(
                                        color: reservation.status == 'aprobada'
                                            ? Colors.green.shade800
                                            : Colors.orange.shade800,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        if (_getReservationsForDay(_selectedDay!).isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No hay reservas para este día'),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
