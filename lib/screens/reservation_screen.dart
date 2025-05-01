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
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime =
      TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
  CommonArea? _selectedArea;
  List<CommonArea> _commonAreas = [];
  List<Reservation> _existingReservations = [];
  bool _isLoading = true;
  String? _errorMessage;

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

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;

        // Asegurar que la hora de fin sea posterior a la hora de inicio
        if (_timeToDouble(_endTime) <= _timeToDouble(_startTime)) {
          _endTime = TimeOfDay(
            hour: _startTime.hour + 1,
            minute: _startTime.minute,
          );
        }
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        if (_timeToDouble(picked) > _timeToDouble(_startTime)) {
          _endTime = picked;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('La hora de fin debe ser posterior a la hora de inicio'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  double _timeToDouble(TimeOfDay time) {
    return time.hour + time.minute / 60.0;
  }

  bool _isTimeSlotAvailable() {
    if (_selectedDay == null || _selectedArea == null) return false;

    // Crear fechas completas con la fecha seleccionada y las horas de inicio y fin
    final startDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      _endTime.hour,
      _endTime.minute,
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
    if (_selectedDay == null || _selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un día y un área común'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isTimeSlotAvailable()) {
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
      final authService = AuthService(SupabaseService.client);
      final user = await authService.getCurrentUser();

      if (user == null || user.unitId == null) {
        throw Exception(
            'Debes estar asociado a una unidad para hacer reservas');
      }

      // Crear fechas completas con la fecha seleccionada y las horas de inicio y fin
      final startDateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        _endTime.hour,
        _endTime.minute,
      );

      // Crear la reserva
      final reservation = Reservation(
        id: 0, // El ID será asignado por la base de datos (SERIAL)
        unitId: user.unitId!, // Convertir String a entero
        commonAreaId: _selectedArea!.id, // Ya es un entero
        startDate: startDateTime,
        endDate: endDateTime,
        status: 'pendiente', // Las reservas se crean con estado pendiente
      );

      final reservationService = ReservationService(SupabaseService.client);
      await reservationService.createReservation(reservation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Reserva creada exitosamente. Pendiente de aprobación.'),
            backgroundColor: Colors.green,
          ),
        );

        // Recargar reservas
        await _loadReservations();
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

  // Función para manejar la creación de reserva
  void _handleCreateReservation() {
    if (_isTimeSlotAvailable() && !_isLoading) {
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
                          });
                          _loadReservations();
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
                              });
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

                      // Selector de horas
                      const Text(
                        'Selecciona el horario',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectStartTime,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Hora de inicio',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_startTime.format(context)),
                                    const Icon(Icons.access_time),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: _selectEndTime,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Hora de fin',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_endTime.format(context)),
                                    const Icon(Icons.access_time),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
                                _buildReservationDetail('Horario',
                                    '${_startTime.format(context)} - ${_endTime.format(context)}'),
                                _buildReservationDetail(
                                  'Disponibilidad',
                                  _isTimeSlotAvailable()
                                      ? 'Disponible'
                                      : 'No disponible (conflicto con otra reserva)',
                                  color: _isTimeSlotAvailable()
                                      ? Colors.green
                                      : Colors.red,
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
                        onPressed: _isTimeSlotAvailable() && !_isLoading
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
