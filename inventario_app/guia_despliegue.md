# Guía de Despliegue y Configuración Inicial

Esta guía está dirigida a desarrolladores o administradores que deseen instalar la aplicación desde cero y conectarla a su propia cuenta de Supabase.

## 1. Configuración de Supabase

### Paso 1: Crear Proyecto
1.  Ve a [supabase.com](https://supabase.com) y crea una cuenta.
2.  Crea un "New Project".
3.  Asigna un nombre (ej. `InventarioApp`) y una contraseña segura para la base de datos.
4.  Selecciona la región más cercana a ti.

### Paso 2: Ejecutar Script SQL
Una vez creado el proyecto:
1.  Ve al **SQL Editor** en el menú lateral.
2.  Crea una **New Query**.
3.  Copia y pega el siguiente código SQL para crear la tabla y configurar la seguridad:

```sql
-- 1. Crear tabla 'inventario'
CREATE TABLE public.inventario (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    codigo text NULL,
    tipo text NULL,
    subtipo text NULL,
    ubicacion text NULL,
    estado text NULL,
    foto_url text NULL,
    fecha timestamp without time zone NULL,
    CONSTRAINT inventario_pkey PRIMARY KEY (id)
);

-- 2. Habilitar seguridad (RLS)
ALTER TABLE inventario ENABLE ROW LEVEL SECURITY;

-- 3. Políticas de acceso (Público para la Demo)
CREATE POLICY "Permitir lectura pública" ON inventario FOR SELECT TO anon USING (true);
CREATE POLICY "Permitir inserción pública" ON inventario FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Permitir actualización pública" ON inventario FOR UPDATE TO anon USING (true);
CREATE POLICY "Permitir eliminación pública" ON inventario FOR DELETE TO anon USING (true);

-- 4. Configurar Storage (Fotos)
INSERT INTO storage.buckets (id, name, public) VALUES ('inventario_fotos', 'inventario_fotos', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public Access Get" ON storage.objects FOR SELECT TO anon USING ( bucket_id = 'inventario_fotos' );
CREATE POLICY "Public Access Upload" ON storage.objects FOR INSERT TO anon WITH CHECK ( bucket_id = 'inventario_fotos' );
```
4.  Ejecuta el script (Run).

## 2. Configuración del Proyecto Flutter

### Paso 1: Obtener Credenciales
1.  En Supabase, ve a **Project Settings** (ícono de engranaje) -> **API**.
2.  Copia la **Project URL**.
3.  Copia la **anon public** key.

### Paso 2: Crear archivo `.env`
1.  En la raíz del proyecto (al mismo nivel que `pubspec.yaml`), crea un archivo llamado `.env`.
2.  Pega tus credenciales en el siguiente formato:

```env
SUPABASE_URL=TU_URL_DE_SUPABASE_AQUI
SUPABASE_ANON_KEY=TU_CLAVE_ANON_AQUI
```

> **IMPORTANTE**: Nunca subas este archivo `.env` a GitHub. Asegúrate de que esté en tu `.gitignore`.

### Paso 3: Instalar Dependencias
Ejecuta en tu terminal:
```bash
flutter pub get
```

### Paso 4: Ejecutar la App
```bash
flutter run
```

¡Listo! La aplicación ahora está conectada a tu propia base de datos.
