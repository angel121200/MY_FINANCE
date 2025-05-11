import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'base_de_datos.dart';
//Cabrera, Arce,Carrero, Martinez, Varela, Villalta.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Finance',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const MyHomePage(),
      debugShowCheckedModeBanner:
          false, // Opcional: para quitar el banner de debug
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double ingresos = 0.00;
  double gastos = 0.00;
  double balance = 0.00;
  // Cambia el tipo de la lista para almacenar objetos Transaction
  List<Transaction> registroOperaciones = [];

  // Instancia de tu gestor de base de datos
  final DatabaseHelper _dbHelper = DatabaseHelper();

  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  String _tipoTransaccion = ''; // Puedes inicializarlo a vacío o null

  // Este método se llama cuando el State se crea
  @override
  void initState() {
    super.initState();
    // Carga las transacciones existentes desde la base de datos al iniciar
    _cargarTransacciones();
  }

  // Función para cargar todas las transacciones desde la base de datos
  Future<void> _cargarTransacciones() async {
    List<Transaction> transacciones = await _dbHelper.getTransactions();
    // Actualiza el estado con los datos cargados
    if (!mounted)
      return; // Evita usar BuildContext si el widget ya no está montado
    setState(() {
      registroOperaciones = transacciones;
      _calcularBalance(); // Recalcula los totales después de cargar los datos
    });
  }

  // Función para calcular ingresos, gastos y balance a partir de la lista de transacciones
  void _calcularBalance() {
    ingresos = 0.00;
    gastos = 0.00;
    balance = 0.00;
    for (var operacion in registroOperaciones) {
      if (operacion.tipo == 'Ingreso') {
        // Ahora accedes con .tipo
        ingresos += operacion.cantidad; // Ahora accedes con .cantidad
        balance += operacion.cantidad;
      } else if (operacion.tipo == 'Gasto') {
        // Ahora accedes con .tipo
        gastos += operacion.cantidad; // Ahora accedes con .cantidad
        balance -= operacion.cantidad;
      }
    }
  }

  void _agregarTransaccion() async {
    // La función debe ser async para usar await
    // Validación básica de campos
    // Ahora la validación se enfoca en nombre, monto y que _tipoTransaccion haya sido establecido por los botones
    if (_montoController.text.isNotEmpty &&
        _tipoTransaccion
            .isNotEmpty && // <-- Verifica que _tipoTransaccion no esté vacío
        _nombreController.text.isNotEmpty) {
      double monto = double.tryParse(_montoController.text) ?? 0.00;

      // Crea un objeto Transaction con los datos del formulario
      Transaction nuevaTransaccion = Transaction(
        tipo:
            _tipoTransaccion, // Usa el tipo que fue establecido por el botón presionado
        nombre: _nombreController.text,
        cantidad: monto,
        fecha: DateTime.now(), // Usa la fecha actual
      );

      // Inserta la nueva transacción en la base de datos
      await _dbHelper.insertTransaction(nuevaTransaccion);

      // Después de insertar, recarga la lista completa de transacciones desde la base de datos
      // Esto actualiza la UI con el nuevo elemento y recalcula los totales
      if (!mounted)
        return; // Evita usar BuildContext si el widget ya no está montado
      _cargarTransacciones();

      // Limpia los controladores y resetea el tipo de transacción
      _montoController.clear();
      _nombreController.clear();
      _tipoTransaccion =
          ''; // IMPORTANTE: Resetea el tipo para que se deba seleccionar de nuevo para la próxima transacción

      // Opcional: Mostrar un mensaje de éxito
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${nuevaTransaccion.tipo} agregado con éxito.'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Muestra un SnackBar si algún campo está vacío
      if (!mounted)
        return; // Evita usar BuildContext si el widget ya no está montado
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, ingrese el monto, el nombre y seleccione el tipo de transacción (Ingreso/Gasto).',
          ),
        ),
      );
    }
  }

  void _mostrarRegistro() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Registro de Operaciones'),
          content: SizedBox(
            width: double.maxFinite,
            // Usa una altura fija o un Expanded si el diálogo es muy largo
            height:
                MediaQuery.of(context).size.height * 0.6, // Ejemplo de altura
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: registroOperaciones.length,
              itemBuilder: (context, index) {
                // Accede directamente al objeto Transaction de la lista
                final operacion = registroOperaciones[index];

                // Formatea la fecha usando el objeto DateTime directamente
                final fechaFormateada = DateFormat(
                  'yyyy-MM-dd – kk:mm',
                ).format(operacion.fecha); // Accedes a la fecha con .fecha

                Color colorTexto;
                if (operacion.tipo == 'Ingreso') {
                  // Accedes con .tipo
                  colorTexto = Colors.green;
                } else if (operacion.tipo == 'Gasto') {
                  // Accedes con .tipo
                  colorTexto = Colors.red;
                } else {
                  colorTexto = Colors.black;
                }

                return ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        // Accedes a tipo y nombre con .tipo y .nombre
                        '${operacion.tipo}: ${operacion.nombre}',
                        style: TextStyle(color: colorTexto),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Llama a la función de eliminar pasando el ID de la transacción
                          // Asegúrate de que el ID no sea null (debería tener uno al ser leído de la DB)
                          _eliminarOperacion(operacion.id!);
                        },
                        child: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    // Accedes a cantidad con .cantidad
                    'Cantidad: \$${operacion.cantidad.toStringAsFixed(2)} - $fechaFormateada',
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Función para eliminar una operación, ahora por su ID de la base de datos
  void _eliminarOperacion(int id) async {
    // La función debe ser async y recibir el ID
    // Elimina la transacción de la base de datos usando el helper
    await _dbHelper.deleteTransaction(id);

    // Recarga la lista de transacciones desde la base de datos
    // Esto actualizará la UI y recalculará el balance
    if (!mounted)
      return; // Evita usar BuildContext si el widget ya no está montado
    _cargarTransacciones();

    // Muestra un mensaje de confirmación
    if (!mounted)
      return; // Evita usar BuildContext si el widget ya no está montado
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Operación eliminada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // --- FUNCIÓN MODIFICADA: Borrar la última transacción de Ingreso ---
  void _borrarIngresos() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar'),
          content: const Text(
            '¿Está seguro de que desea borrar la última transacción de ingreso?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
                // Obtiene la última transacción de ingreso
                Transaction? lastIngreso = await _dbHelper
                    .getLastTransactionByType('Ingreso');

                if (!mounted)
                  return; // Evita usar BuildContext si el widget ya no está montado

                if (lastIngreso != null && lastIngreso.id != null) {
                  // Si existe una última transacción de ingreso, la elimina por su ID
                  await _dbHelper.deleteTransaction(lastIngreso.id!);
                  // Recarga la lista de transacciones para actualizar la UI y totales
                  _cargarTransacciones();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Último ingreso borrado'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  // Si no hay transacciones de ingreso para borrar
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No hay ingresos para borrar.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );
  }
  // --- FIN DE LA FUNCIÓN MODIFICADA ---

  // --- FUNCIÓN MODIFICADA: Borrar la última transacción de Gasto ---
  void _borrarGastos() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar'),
          content: const Text(
            '¿Está seguro de que desea borrar la última transacción de gasto?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
                // Obtiene la última transacción de gasto
                Transaction? lastGasto = await _dbHelper
                    .getLastTransactionByType('Gasto');

                if (!mounted)
                  return; // Evita usar BuildContext si el widget ya no está montado

                if (lastGasto != null && lastGasto.id != null) {
                  // Si existe una última transacción de gasto, la elimina por su ID
                  await _dbHelper.deleteTransaction(lastGasto.id!);
                  // Recarga la lista de transacciones para actualizar la UI y totales
                  _cargarTransacciones();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Último gasto borrado'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  // Si no hay transacciones de gasto para borrar
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No hay gastos para borrar.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );
  }
  // --- FIN DE LA FUNCIÓN MODIFICADA ---

  // Esta función construye las tarjetas de Ingresos, Gastos y Balance
  Widget _buildCard(
    String title,
    String value,
    Color color,
    double balanceValue,
  ) {
    Color valueColor = Colors.black;
    if (title == 'Balance' && balanceValue < 0) {
      valueColor = Colors.orange;
    }

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          // Mantenemos SizedBox aquí para dar un tamaño consistente a las tarjetas
          width: 100, // Ancho fijo
          height: 80, // Alto fijo
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                value,
                style: TextStyle(fontSize: 16, color: valueColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('My Finance', style: TextStyle(color: Colors.red)),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Tu flujo, tu control, tu finanza',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  // Usamos _buildCard directamente, que ya tiene SizedBox
                  _buildCard(
                    'Ingresos',
                    '\$${ingresos.toStringAsFixed(2)}',
                    Colors.lightGreen.shade100,
                    balance,
                  ),
                  const SizedBox(width: 16), // Espacio entre tarjetas
                  _buildCard(
                    'Gastos',
                    '\$${gastos.toStringAsFixed(2)}',
                    Colors.red.shade100,
                    balance,
                  ),
                  const SizedBox(width: 16), // Espacio entre tarjetas
                  _buildCard(
                    'Balance',
                    '\$${balance.toStringAsFixed(2)}',
                    Colors.lightBlue.shade100,
                    balance,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la transacción',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto de la transacción',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _tipoTransaccion = 'Ingreso';
                    });
                    _agregarTransaccion(); // Llama a la función para agregar después de establecer el tipo
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _tipoTransaccion == 'Ingreso'
                            ? Colors.green
                            : Colors.grey[300],
                  ),
                  child: Text(
                    'Ingreso',
                    style: TextStyle(
                      color:
                          _tipoTransaccion == 'Ingreso'
                              ? Colors.white
                              : Colors.black,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _tipoTransaccion = 'Gasto';
                    });
                    _agregarTransaccion(); // Llama a la función para agregar después de establecer el tipo
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _tipoTransaccion == 'Gasto'
                            ? Colors.red
                            : Colors.grey[300],
                  ),
                  child: Text(
                    'Gasto',
                    style: TextStyle(
                      color:
                          _tipoTransaccion == 'Gasto'
                              ? Colors.white
                              : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _mostrarRegistro,
              child: const Text('Mostrar Registro'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // --- INICIO DE MODIFICACIÓN DE TAMAÑO Y ESPACIO ---
                Expanded(
                  // Permite que el botón ocupe el espacio disponible
                  child: Padding(
                    // Añade padding alrededor del botón
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                    ), // Ajusta el padding horizontal
                    child: ElevatedButton(
                      onPressed:
                          _borrarIngresos, // Llama a la función modificada
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 8.0,
                        ), // Ajusta el padding interno del botón
                        textStyle: const TextStyle(
                          fontSize: 12,
                        ), // Opcional: Ajusta el tamaño del texto si es necesario
                      ),
                      child: const Text(
                        'Borrar Último Ingreso', // Texto actualizado
                        style: TextStyle(color: Colors.white),
                        textAlign:
                            TextAlign
                                .center, // Centra el texto si se reduce el tamaño
                      ),
                    ),
                  ),
                ),
                Expanded(
                  // Permite que el botón ocupe el espacio disponible
                  child: Padding(
                    // Añade padding alrededor del botón
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                    ), // Ajusta el padding horizontal
                    child: ElevatedButton(
                      onPressed: _borrarGastos, // Llama a la función modificada
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 8.0,
                        ), // Ajusta el padding interno del botón
                        textStyle: const TextStyle(
                          fontSize: 12,
                        ), // Opcional: Ajusta el tamaño del texto si es necesario
                      ),
                      child: const Text(
                        'Borrar Último Gasto', // Texto actualizado
                        style: TextStyle(color: Colors.white),
                        textAlign:
                            TextAlign
                                .center, // Centra el texto si se reduce el tamaño
                      ),
                    ),
                  ),
                ),
                // --- FIN DE MODIFICACIÓN DE TAMAÑO Y ESPACIO ---
              ],
            ),
          ],
        ),
      ),
    );
  }
}

