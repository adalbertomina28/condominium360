import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/custom_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  User? _currentUser;
  List<Payment> _pendingPayments = [];
  List<Reservation> _upcomingReservations = [];
  List<Post> _latestPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar usuario actual
      final authService = AuthService(SupabaseService.client);
      _currentUser = await authService.getCurrentUser();

      if (_currentUser != null && _currentUser!.unitId != null) {
        // Cargar pagos pendientes
        final paymentService = PaymentService(SupabaseService.client);
        final payments = await paymentService.getPaymentsByUnitId(_currentUser!.unitId!);
        _pendingPayments = payments.where((p) => p.status == 'pendiente').toList();

        // Cargar próximas reservas
        final reservationService = ReservationService(SupabaseService.client);
        final reservations = await reservationService.getReservationsByUnitId(_currentUser!.unitId!);
        _upcomingReservations = reservations
            .where((r) => r.startDate.isAfter(DateTime.now()))
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
        if (_upcomingReservations.length > 3) {
          _upcomingReservations = _upcomingReservations.sublist(0, 3);
        }
      }

      // Cargar últimos avisos
      final postService = PostService(SupabaseService.client);
      final posts = await postService.getPostsByType('aviso');
      _latestPosts = posts.take(3).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Condominium 360°'),
            if (_currentUser?.role == 'admin')
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = AuthService(SupabaseService.client);
              await authService.signOut();
              if (mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _currentUser?.name ?? 'Usuario',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _currentUser?.email ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _currentUser?.role == 'admin' ? Colors.red.shade700 : Colors.green.shade700,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _currentUser?.role == 'admin' ? 'Admin' : 'Residente',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: true,
              onTap: () {
                context.pop();
              },
            ),
            
            // Opciones para residentes
            if (_currentUser?.role != 'admin') ...[
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Reservar área'),
                onTap: () {
                  context.pop();
                  context.push('/reservation');
                },
              ),
              ListTile(
                leading: const Icon(Icons.support_agent),
                title: const Text('Soporte'),
                onTap: () {
                  context.pop();
                  context.push('/support');
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Comunidad'),
                onTap: () {
                  context.pop();
                  context.push('/community');
                },
              ),
              ListTile(
                leading: const Icon(Icons.payment),
                title: const Text('Pagos'),
                onTap: () {
                  context.pop();
                  context.push('/payments');
                },
              ),
            ],
            
            // Opciones exclusivas para administradores
            if (_currentUser?.role == 'admin') ...[
              ListTile(
                leading: const Icon(Icons.approval),
                title: const Text('Aprobar Reservas'),
                onTap: () {
                  context.pop();
                  context.push('/admin/reservations');
                },
              ),
              ListTile(
                leading: const Icon(Icons.people_alt),
                title: const Text('Gestionar Residentes'),
                onTap: () {
                  context.pop();
                  context.push('/admin/residents');
                },
              ),
              ListTile(
                leading: const Icon(Icons.announcement),
                title: const Text('Publicar Anuncios'),
                onTap: () {
                  context.pop();
                  context.push('/admin/announcements');
                },
              ),
              ListTile(
                leading: const Icon(Icons.payments),
                title: const Text('Gestionar Pagos'),
                onTap: () {
                  context.pop();
                  context.push('/admin/payments');
                },
              ),
            ],
            
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                context.pop();
                context.push('/settings');
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bienvenida
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
                            Text(
                              'Bienvenido, ${_currentUser?.name.split(' ').first ?? 'Usuario'}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentUser?.role == 'admin' 
                                ? 'Panel de administración del condominio.'
                                : 'Aquí tienes un resumen de tu actividad reciente.',
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
                    
                    // Contenido específico para administradores
                    if (_currentUser?.role == 'admin') ...[  
                      _buildSectionTitle('Reservas pendientes de aprobación', Icons.approval),
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
                              const Text('Tienes 3 reservas pendientes de aprobación'),
                              const SizedBox(height: 16),
                              CustomButton(
                                text: 'Ver reservas pendientes',
                                icon: Icons.arrow_forward,
                                onPressed: () {
                                  context.push('/admin/reservations');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildSectionTitle('Residentes activos', Icons.people),
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
                              const Text('12 residentes registrados en el sistema'),
                              const SizedBox(height: 16),
                              CustomButton(
                                text: 'Gestionar residentes',
                                icon: Icons.arrow_forward,
                                onPressed: () {
                                  context.push('/admin/residents');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildSectionTitle('Anuncios recientes', Icons.announcement),
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
                              const Text('Último anuncio publicado hace 3 días'),
                              const SizedBox(height: 16),
                              CustomButton(
                                text: 'Publicar nuevo anuncio',
                                icon: Icons.arrow_forward,
                                onPressed: () {
                                  context.push('/admin/announcements');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    // Contenido específico para residentes
                    if (_currentUser?.role != 'admin') ...[  
                      // Pagos pendientes
                      _buildSectionTitle('Pagos pendientes', Icons.payment),
                      const SizedBox(height: 8),
                      _pendingPayments.isEmpty
                          ? _buildEmptyState('No tienes pagos pendientes')
                          : Column(
                              children: _pendingPayments
                                  .map((payment) => _buildPaymentCard(payment))
                                  .toList(),
                            ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Ver todos los pagos',
                        isOutlined: true,
                        icon: Icons.arrow_forward,
                        onPressed: () {
                          context.push('/payments');
                        },
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle('Próximas reservas', Icons.calendar_today),
                      const SizedBox(height: 8),
                      _upcomingReservations.isEmpty
                          ? _buildEmptyState('No tienes reservas próximas')
                          : Column(
                              children: _upcomingReservations
                                  .map((reservation) => _buildReservationCard(reservation))
                                  .toList(),
                            ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Reservar área común',
                        isOutlined: true,
                        icon: Icons.add,
                        onPressed: () {
                          context.push('/reservations');
                        },
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle('Últimos anuncios', Icons.announcement),
                      const SizedBox(height: 8),
                      _latestPosts.isEmpty
                          ? _buildEmptyState('No hay anuncios recientes')
                          : Column(
                              children: _latestPosts
                                  .map((post) => _buildPostCard(post))
                                  .toList(),
                            ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Ver todos los avisos',
                        isOutlined: true,
                        icon: Icons.arrow_forward,
                        onPressed: () {
                          context.push('/community');
                        },
                      ),
                      const SizedBox(height: 24),
                    // Cierre del if para residentes
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
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
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.receipt,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Vence: ${_formatDate(payment.date)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '\$${payment.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    return FutureBuilder<CommonArea>(
      future: CommonAreaService(SupabaseService.client).getCommonAreaById(reservation.commonAreaId),
      builder: (context, snapshot) {
        final areaName = snapshot.hasData ? snapshot.data!.name : 'Área común';
        
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.event,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        areaName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_formatDate(reservation.startDate)} - ${_formatTime(reservation.startDate)} a ${_formatTime(reservation.endDate)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: reservation.status == 'aprobada'
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    reservation.status == 'aprobada' ? 'Aprobada' : 'Pendiente',
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
      },
    );
  }

  Widget _buildPostCard(Post post) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.announcement,
                    color: Colors.purple.shade800,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(post.date),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.content.length > 100
                  ? '${post.content.substring(0, 100)}...'
                  : post.content,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Navegar a la vista detallada del post
                },
                child: const Text('Leer más'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
