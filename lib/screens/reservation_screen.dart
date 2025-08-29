import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/custom_button.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({Key? key}) : super(key: key);

  @override
  _ReservationScreenState createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CommonArea? _selectedArea;
  List<CommonArea> _commonAreas = [];
  List<Reservation> _existingReservations = [];
  List<AreaSchedule> _availableSchedules = [];
  AreaSchedule? _selectedSchedule;
  int _selectedPeople = 1;
  bool _isLoading = true;
  String? _errorMessage;
  User? _currentUser;
  Unit? _userUnit;
  AreaCapacity? _areaCapacity;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService(SupabaseService.client);
      final commonAreaService = CommonAreaService(SupabaseService.client);
      final unitService = UnitService(SupabaseService.client);

      // Cargar usuario actual
      _currentUser = await authService.getCurrentUser();
      if (_currentUser == null || _currentUser!.unitId == null) {
        setState(() {
          _errorMessage = 'Debes estar asociado a una unidad para hacer reservas';
        });
        return;
      }

      // Cargar unidad del usuario
      _userUnit = await unitService.getUnitById(_currentUser!.unitId!);

      // Cargar áreas comunes del condominio
      _commonAreas = await commonAreaService
          .getCommonAreasByCondominiumId(_userUnit!.condominiumId);

      if (_commonAreas.isNotEmpty) {
        _selectedArea = _commonAreas.first;
        await _loadReservations();
        await _loadAvailableSchedules();
        await _loadAreaCapacity();
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
      _existingReservations = await reservationService
          .getReservationsByCommonAreaId(_selectedArea!.id);
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar reservas: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAvailableSchedules() async {
    if (_selectedArea == null || _selectedDay == null) return;

    try {
      final scheduleService = AreaScheduleService(SupabaseService.client);
      final weekdayNames = ['', 'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'];
      final weekdayName = weekdayNames[_selectedDay!.weekday];
      
      _availableSchedules = await scheduleService.getSchedulesForWeekday(
        _selectedArea!.id,
        weekdayName,
      );
      
      // Reset selected schedule if it's not available anymore
      if (_selectedSchedule != null && 
          !_availableSchedules.any((s) => s.id == _selectedSchedule!.id)) {
        _selectedSchedule = null;
      }
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar horarios: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAreaCapacity() async {
    if (_selectedArea == null) return;

    try {
      final scheduleService = AreaScheduleService(SupabaseService.client);
      _areaCapacity = await scheduleService.getAreaCapacity(_selectedArea!.id);
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Capacity is optional, so we don't show an error
      _areaCapacity = null;
    }
  }

  bool _hasUserReservationForDay() {
    if (_selectedDay == null || _selectedArea == null || _currentUser == null) {
      return false;
    }

    return _existingReservations.any((reservation) {
      return reservation.unitId == _currentUser!.unitId &&
          reservation.commonAreaId == _selectedArea!.id &&
          reservation.startDate.year == _selectedDay!.year &&
          reservation.startDate.month == _selectedDay!.month &&
          reservation.startDate.day == _selectedDay!.day;
    });
  }

  bool _isScheduleAvailable(AreaSchedule schedule) {
    if (_selectedDay == null || _selectedArea == null) return false;

    // Crear fechas completas con la fecha seleccionada y el horario del schedule
    final startDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      schedule.startTime.hour,
      schedule.startTime.minute,
    );

    final endDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      schedule.endTime.hour,
      schedule.endTime.minute,
    );

    // Verificar si hay conflictos con reservas existentes
    for (final reservation in _existingReservations) {
      if (reservation.commonAreaId == _selectedArea!.id) {
        // Verificar si hay solapamiento
        if (!(endDateTime.isBefore(reservation.startDate) ||
            startDateTime.isAfter(reservation.endDate))) {
          return false;
        }
      }
    }

    return true;
  }

  Future<void> _createReservation() async {
    if (_selectedDay == null || _selectedArea == null || _selectedSchedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un día, área común y horario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_hasUserReservationForDay()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya tienes una reserva para este día en esta área'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isScheduleAvailable(_selectedSchedule!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El horario seleccionado no está disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_currentUser == null || _currentUser!.unitId == null) {
        throw Exception('Debes estar asociado a una unidad para hacer reservas');
      }

      // Crear fechas completas con la fecha seleccionada y el horario del schedule
      final startDateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        _selectedSchedule!.startTime.hour,
        _selectedSchedule!.startTime.minute,
      );

      final endDateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        _selectedSchedule!.endTime.hour,
        _selectedSchedule!.endTime.minute,
      );

      // Crear la reserva
      final reservation = Reservation(
        id: 0,
        unitId: _currentUser!.unitId!,
        commonAreaId: _selectedArea!.id,
        startDate: startDateTime,
        endDate: endDateTime,
        status: 'pendiente',
        people: _selectedPeople,
      );

      final reservationService = ReservationService(SupabaseService.client);
      await reservationService.createReservation(reservation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva creada exitosamente. Pendiente de aprobación.'),
            backgroundColor: Colors.green,
          ),
        );

        // Recargar datos
        await _loadReservations();
        await _loadAvailableSchedules();
        
        // Reset selections
        _selectedSchedule = null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear la reserva: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          reservation.startDate.day == day.day &&
          reservation.commonAreaId == _selectedArea?.id;
    }).toList();
  }

  void _handleCreateReservation() {
    if (_selectedSchedule != null && 
        _isScheduleAvailable(_selectedSchedule!) && 
        !_isLoading &&
        !_hasUserReservationForDay()) {
      _createReservation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservar Área Común'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Reintentar',
                        onPressed: _loadData,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selector de área común
                      const Text(
                        'Selecciona un área común',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<CommonArea>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        value: _selectedArea,
                        items: _commonAreas.map((area) {
                          return DropdownMenuItem<CommonArea>(
                            value: area,
                            child: Text(area.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedArea = value;
                            _selectedSchedule = null;
                          });
                          _loadReservations();
                          _loadAvailableSchedules();
                          _loadAreaCapacity();
                        },
                      ),
                      const SizedBox(height: 24),

                      // Calendario
                      const Text(
                        'Selecciona una fecha',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TableCalendar(
                            firstDay: DateTime.now(),
                            lastDay:
                                DateTime.now().add(const Duration(days: 365)),
                            focusedDay: _focusedDay,
                            calendarFormat: _calendarFormat,
                            selectedDayPredicate: (day) {
                              return isSameDay(_selectedDay, day);
                            },
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                                _selectedSchedule = null;
                              });
                              _loadAvailableSchedules();
                            },
                            onPageChanged: (focusedDay) {
                              _focusedDay = focusedDay;
                              _loadReservations();
                            },
                            calendarStyle: const CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: Colors.deepPurple,
                                shape: BoxShape.circle,
                              ),
                            ),
                            eventLoader: (day) {
                              return _getReservationsForDay(day);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Selector de horarios disponibles
                      const Text(
                        'Selecciona un horario disponible',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_availableSchedules.isEmpty && _selectedDay != null)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No hay horarios disponibles para este día',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: _availableSchedules.map((schedule) {
                            final isAvailable = _isScheduleAvailable(schedule);
                            final isSelected = _selectedSchedule?.id == schedule.id;
                            
                            return ChoiceChip(
                              label: Text(
                                '${schedule.startTime.format(context)} - ${schedule.endTime.format(context)}',
                                style: TextStyle(
                                  color: isAvailable 
                                    ? (isSelected ? Colors.white : Colors.black87)
                                    : Colors.grey,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: isAvailable ? (selected) {
                                setState(() {
                                  _selectedSchedule = selected ? schedule : null;
                                });
                              } : null,
                              selectedColor: Colors.deepPurple,
                              backgroundColor: isAvailable ? null : Colors.grey.shade200,
                              disabledColor: Colors.grey.shade200,
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),

                      // Selector de número de personas
                      if (_areaCapacity != null) ...[
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
                              onPressed: _selectedPeople > 1 ? () {
                                setState(() {
                                  _selectedPeople--;
                                });
                              } : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_selectedPeople',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _selectedPeople < _areaCapacity!.maxPeople ? () {
                                setState(() {
                                  _selectedPeople++;
                                });
                              } : null,
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Máx: ${_areaCapacity!.maxPeople}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Resumen de la reserva
                      if (_selectedDay != null && _selectedArea != null)
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Resumen de la reserva',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildReservationDetail(
                                    'Área', _selectedArea!.name),
                                _buildReservationDetail(
                                    'Fecha',
                                    DateFormat('dd/MM/yyyy')
                                        .format(_selectedDay!)),
                                if (_selectedSchedule != null) ...[
                                  _buildReservationDetail('Horario',
                                      '${_selectedSchedule!.startTime.format(context)} - ${_selectedSchedule!.endTime.format(context)}'),
                                  _buildReservationDetail('Personas', '$_selectedPeople'),
                                  _buildReservationDetail(
                                    'Disponibilidad',
                                    _isScheduleAvailable(_selectedSchedule!)
                                        ? 'Disponible'
                                        : 'No disponible',
                                    color: _isScheduleAvailable(_selectedSchedule!)
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ] else
                                  const Text(
                                    'Selecciona un horario para ver el resumen',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Botón para crear la reserva
                      CustomButton(
                        text: 'Crear Reserva',
                        icon: Icons.calendar_today,
                        onPressed: (_selectedSchedule != null && 
                                   _isScheduleAvailable(_selectedSchedule!) && 
                                   !_isLoading &&
                                   !_hasUserReservationForDay())
                            ? _handleCreateReservation
                            : null,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 24),

                      // Reservas existentes para el día seleccionado
                      if (_selectedDay != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reservas para ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._getReservationsForDay(_selectedDay!)
                                .map((reservation) {
                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.event,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _selectedArea?.name ??
                                                  'Área común',
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
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              reservation.status == 'aprobada'
                                                  ? Colors.green.shade100
                                                  : Colors.orange.shade100,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          reservation.status == 'aprobada'
                                              ? 'Aprobada'
                                              : 'Pendiente',
                                          style: TextStyle(
                                            color:
                                                reservation.status == 'aprobada'
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
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildReservationDetail(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
