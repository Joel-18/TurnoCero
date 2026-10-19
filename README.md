# TurnoCero

Agenda médica para descubrir especialistas, revisar disponibilidad y reservar consultas. Proyecto de portafolio de Joel Ortiz.

## Caso de estudio

La opción **Sobre el proyecto** dentro de la aplicación presenta el reto, la solución, las decisiones de diseño, el stack y el alcance del prototipo en un formato listo para recorrer durante una revisión de portafolio. El catálogo, las valoraciones, la trayectoria y los horarios de los profesionales son datos ilustrativos; no representan médicos reales ni disponibilidad clínica.

Las fichas individuales muestran especialidad, clínica, precio y próxima disponibilidad, y enlazan directamente con el flujo de reserva.

## Demo

- Sin credenciales de Supabase, TurnoCero usa datos de demostración locales. Puedes probar la reserva, el perfil y el panel de administración demo; los cambios quedan en el navegador actual.
- Con Supabase, pacientes inician sesión con enlace de correo y guardan sus datos y citas en la base de datos.
- Capturas: agrega imágenes actuales del modo claro y oscuro en `docs/screenshots/` y enlázalas aquí después de iniciar la app. No uses capturas con información personal real.

## Funciones

- Búsqueda y filtros por especialidad, con conteos de especialistas y clínicas calculados desde los datos disponibles.
- Reserva en varios pasos con horarios ocupados deshabilitados y validación final contra reservas simultáneas.
- Perfil de paciente con nombre y teléfono, persistente en modo demo o Supabase.
- Historial de citas con filtros y cancelación.
- Panel de administración para revisar, confirmar, poner pendiente o cancelar citas. En demo usa citas locales; en Supabase requiere un perfil con rol `admin`.
- Estados de carga, errores y confirmación; diseño adaptable y modo claro/oscuro.

## Tecnologías

React, TypeScript, Vite, Supabase Auth, PostgreSQL, Row Level Security y Lucide.

## Ejecutar localmente

1. Instala Node.js 20 o superior.
2. Ejecuta `npm install`.
3. Ejecuta `npm run dev` y abre la dirección local que imprime Vite.
4. Sin variables de Supabase, la aplicación inicia en modo demo.

## Activar Supabase

1. Crea un proyecto en Supabase.
2. Ejecuta `supabase/schema.sql` en el SQL Editor. El script crea perfiles, políticas RLS, la función para leer solo horarios ocupados y la protección contra dobles reservas.
3. Copia `.env.example` a `.env.local` y configura `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY`. No uses la clave `service_role` en el navegador.
4. En Authentication → URL Configuration, agrega las URL local y desplegada a Redirect URLs.
5. Reinicia Vite e inicia sesión con tu correo. Supabase enviará un enlace de acceso.
6. Para habilitar el panel real, asigna el rol `admin` en `public.profiles` desde el SQL Editor. Ejemplo:

```sql
update public.profiles
set role = 'admin'
where id = (select id from auth.users where email = 'tu-correo@dominio.com');
```

El rol no se puede cambiar desde la pantalla de perfil. Las políticas de base de datos limitan a pacientes a sus datos y permiten al personal administrador gestionar las citas.

## Desplegar en Vercel

Importa el repositorio en Vercel con el comando `npm run build` y la carpeta de salida `dist`. Configura las dos variables de Supabase y añade el dominio desplegado a Redirect URLs.

## Alcance de la demo

El catálogo de profesionales y sus horarios de trabajo son datos de demostración. La restricción de base de datos evita que dos usuarios reserven al mismo profesional, fecha y hora; una clínica real tendría que conectar sus agendas y reglas de disponibilidad.
