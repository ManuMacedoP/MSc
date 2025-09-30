-- ========================================================================================================================
-- 0. Limpieza y creación de la base de datos
-- ========================================================================================================================
DROP DATABASE IF EXISTS artevida;
CREATE DATABASE artevida CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE artevida;

-- ========================================================================================================================
-- 1. Creación de tablas (respetando el orden de las FKs)
-- ========================================================================================================================

-- Actividad
CREATE TABLE actividad (
	nombre_ac 	VARCHAR(100) PRIMARY KEY,
    tipo_ac		ENUM('concierto', 'exposición', 'teatro', 'conferencia') NOT NULL	-- Únicamente los valores especificados en el enunciado
);

-- Artista
CREATE TABLE artista (
	nombre_ar	VARCHAR(100) PRIMARY KEY,
    biografia	TEXT NULL
);

-- Persona
CREATE TABLE persona (
	mail		VARCHAR(100) PRIMARY KEY,
    nombre_pe	VARCHAR(100) NOT NULL,
    apellido1	VARCHAR(100) NOT NULL,
    apellido2	VARCHAR(100) NULL,						-- Null ya que puede haber gente con 1 solo apellido
    telefono1	VARCHAR(100) NULL,						-- No se necesita ningún teléfono obligatoriamente, ya que la entrada se envía al mail
    telefono2	VARCHAR(100) NULL,
    CONSTRAINT mail_format CHECK (INSTR(mail,'@') > 1)	-- Para comprobar que es un email
);

-- Localidad
CREATE TABLE localidad (
	id_localidad	INT PRIMARY KEY,
    nombre_lo		VARCHAR(100) NOT NULL,
    tipo_lo			ENUM('ciudad', 'pueblo') NOT NULL	-- Únicamente los valores especificados en el enunciado
);

-- Ubicación (depende de localidad)
CREATE TABLE ubicacion (
	nombre_ub		VARCHAR(100) NOT NULL,
    id_localidad	INT NOT NULL,
    direccion		VARCHAR(200) NOT NULL,									-- Puede ser una dirección larga
    aforo			INT NOT NULL CHECK (aforo >= 0), 						-- Ya que aforos negativos no tienen sentido
    precio_alquiler	DECIMAL(10,2) NOT NULL CHECK (precio_alquiler >= 0),	-- Ya que precios de alquiler negativos no tienen sentido
    caracteristicas	TEXT NULL,												-- Se permite NULL pues no es crítico
    CONSTRAINT pk_ubicacion PRIMARY KEY (nombre_ub, id_localidad),
    CONSTRAINT fk_ubicacion 
		FOREIGN KEY (id_localidad) REFERENCES localidad(id_localidad)
        ON UPDATE RESTRICT ON DELETE RESTRICT								-- Para proteger la clave de la tabla de entidad, impidiendo que el ID de una localidad se pueda actualizar si hay ubicaciones que la referencian
);

-- Evento (depende de Actividad y Ubicación)
CREATE TABLE evento (
	nombre_ev		VARCHAR(100) NOT NULL,
    fecha			DATETIME NOT NULL,
    precio			DECIMAL(10,2) NOT NULL CHECK (precio >= 0), 	-- Ya que precios negativos no tienen sentido
    descripcion		TEXT NULL,										-- Se permite NULL pues no es crítico
    nombre_ac		VARCHAR(100) NOT NULL,
    nombre_ub		VARCHAR(100) NOT NULL,
    id_localidad	INT NOT NULL,
    CONSTRAINT pk_evento PRIMARY KEY (nombre_ev, fecha),
    CONSTRAINT fk_evento_ac
		FOREIGN KEY (nombre_ac) REFERENCES actividad(nombre_ac)
        ON UPDATE RESTRICT ON DELETE RESTRICT, 						-- Similar a anterior RESTRICT
	CONSTRAINT fk_evento_ub
		FOREIGN KEY (nombre_ub, id_localidad) REFERENCES ubicacion(nombre_ub, id_localidad)
        ON UPDATE RESTRICT ON DELETE RESTRICT						-- Similar a anterior
);

-- Cuesta (relación N:N de Actividad-Artista)
CREATE TABLE cuesta (
	nombre_ac	VARCHAR(100) NOT NULL,
    nombre_ar	VARCHAR(100) NOT NULL,
    dinero		DECIMAL(10,2) NOT NULL CHECK (dinero >= 0),			-- Ya que dinero negativo no tienen sentido
    CONSTRAINT pk_cuesta PRIMARY KEY (nombre_ac, nombre_ar),
    CONSTRAINT fk_cuesta_ac 
		FOREIGN KEY (nombre_ac) REFERENCES actividad(nombre_ac)
        ON UPDATE CASCADE ON DELETE CASCADE, 						-- Para mantener sincronizadas las claves en tablas de relación 
	CONSTRAINT fk_cuesta_ar
		FOREIGN KEY (nombre_ar) REFERENCES artista(nombre_ar)
        ON UPDATE CASCADE ON DELETE CASCADE							-- Similar a anterior CASCADE
);

-- Asiste (relación N:N de Eevnto-Persona)
CREATE TABLE asiste (
	nombre_ev	VARCHAR(100) NOT NULL,
    fecha		DATETIME NOT NULL, 
    mail		VARCHAR(100) NOT NULL,
    valoracion	INT NULL,
    CONSTRAINT pk_asiste PRIMARY KEY (nombre_ev, fecha, mail),
    CONSTRAINT fk_asiste_ev
		FOREIGN KEY (nombre_ev, fecha) REFERENCES evento(nombre_ev, fecha)
        ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_asiste_pe
		FOREIGN KEY (mail) REFERENCES persona(mail)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT rango_valoracion CHECK (valoracion BETWEEN 0 AND 5 OR valoracion IS NULL)	-- Para que cuando el asistente valore tenga que hacerlo entre 0 y 5
);

-- ========================================================================================================================
-- 2. Creación de índices útiles 
-- ========================================================================================================================

-- Ejemplos bien puestos??????????????????????????????

-- Índice para acelerar rangos y ordenaciones por fecha en EVENTO; útil en "fecha con más eventos", listados por fecha, próximos eventos, ORDER BY fecha
CREATE INDEX idx_evento_fecha ON evento(fecha);

-- Índice para filtrar/contar eventos por actividad y unir Actividad → Evento; útil en "eventos por tipo", "nº de eventos por cada actividad", vista de ganancias
CREATE INDEX idx_evento_nombre_ac ON evento(nombre_ac);

-- Índice compuesto alineado con la FK y los JOINs Evento ↔ Asiste; útil en conteo de asistentes por evento, trigger de aforo, GROUP BY (nombre_ev, fecha)
CREATE INDEX idx_asiste_evento ON asiste(nombre_ev, fecha);

-- Índice para búsquedas/agregados por localidad (ciudad/pueblo) vía Ubicación; útil en "ciudad con más eventos", desgloses por ciudad
CREATE INDEX idx_ubicacion_localidad ON ubicacion(id_localidad);

-- ========================================================================================================================
-- 3. Generación de los datos (respetando el orden de las FKs)
-- ========================================================================================================================

-- Actividad
INSERT INTO actividad(nombre_ac, tipo_ac) VALUES
	('VI Festival Clásica Alcobendas', 'concierto'),
    ('Concierto Sinfónico en Auditorio', 'concierto'),
    ('Concierto Jazz en Central', 'concierto'),
	('Exposición Vanguardista 2025', 'exposición'),
    ('Exposición Goya: Obras Maestras', 'exposición'),
    ('Exposición Fotografía Urbana', 'exposición'),
    ('Exposición Arte Contemporáneo', 'exposición'),
	('Obra: La Dama de Alba', 'teatro'),
    ('Teatro: La Casa de Bernarda Alba', 'teatro'),
    ('Teatro Clásico en Español', 'teatro'),
    ('Ciclo IA y Sociedad', 'conferencia'),
    ('Teatro Infantil Familiar', 'teatro'),
    ('Conferencia Tecnología 2025', 'conferencia'),
    ('Conferencia Sostenibilidad', 'conferencia'),
    ('Concierto Rock Madrileño', 'concierto'),
    ('Conferencia Innovación Empresas', 'conferencia');

-- Artista
INSERT INTO artista(nombre_ar, biografia) VALUES
-- Artistas para conciertos
	('Orquesta Sinfónica de Madrid', 'Orquesta clásica de prestigio internacional'),
	('Jazz Quartet Modern', 'Grupo de jazz fusión contemporáneo'),
	('Banda Rock Capital', 'Banda de rock con 10 años de trayectoria'),
	('Coro Ciudad de Madrid', 'Coro sinfónico con amplio repertorio'),
	('DJ Electro Sound', 'DJ especializado en música electrónica'),

-- Artistas para exposiciones
	('Pablo Vanguardista', 'Artista visual de arte contemporáneo'),
	('María Fotógrafa', 'Fotógrafa documental urbana'),
	('Fundación Goya', 'Institución cultural dedicada a Goya'),
	('Ana Escultora', 'Escultora de obras monumentales'),
	('Carlos Pintor', 'Pintor hiperrealista'),

-- Artistas para teatro
	('Compañía Teatral Clásica', 'Especializada en teatro del Siglo de Oro'),
	('Teatro Contemporáneo SL', 'Compañía de teatro moderno'),
	('Teatro Familiar Divertido', 'Teatro infantil y familiar'),
	('Grupo Danza Urbana', 'Compañía de danza contemporánea'),
	('Marionetas Mágicas', 'Espectáculos de marionetas'),

-- Artistas para conferencias
	('Dr. Ana Tecnológica', 'Experta en inteligencia artificial'),
	('Prof. Carlos Sostenible', 'Especialista en desarrollo sostenible'),
	('Consultora Innovación Plus', 'Consultoría en innovación empresarial'),
	('Dra. Laura Médica', 'Investigadora en biotecnología'),
	('Ing. Roberto Verde', 'Ingeniero en energías renovables');

-- Persona
INSERT INTO persona (mail, nombre_pe, apellido1, apellido2, telefono1, telefono2) VALUES
	('gabriel@gm.es','Gabriel','Moreno','Díaz','600555666',NULL),
	('helena@gm.es','Helena','Castillo',NULL,'600666777',NULL),
	('ivan@gm.es','Iván','Romero','Vega',NULL,NULL),
	('julia@gm.es','Julia','Navarro','Silva','600777888','910111111'),
	('kiko@gm.es','Kiko','Hernández',NULL,NULL,NULL),
	('laura@gm.es','Laura','Molina','Reyes','600888999',NULL),
	('mario@gm.es','Mario','Gil','Torres',NULL,NULL),
	('nuria@gm.es','Nuria','Ortega','Castro','600999000','910222222'),
	('oscar@gm.es','Óscar','Delgado',NULL,NULL,NULL),
	('patricia@gm.es','Patricia','Vázquez','Méndez','600000111',NULL),
	('quique@gm.es','Quique','Ramírez',NULL,'600111000',NULL),
	('rosa@gm.es','Rosa','Santos','Iglesias',NULL,NULL),
	('sergio@gm.es','Sergio','Flores','Cabrera','600222111','910333333'),
	('teresa@gm.es','Teresa','Cruz',NULL,NULL,NULL),
	('ulises@gm.es','Ulises','Morales','Paredes','600333222',NULL);
  
-- Localidad
INSERT INTO localidad(id_localidad, nombre_lo, tipo_lo) VALUES
	(1, 'Madrid', 'ciudad'),
    (2, 'Alcobendas', 'ciudad'),
    (3, 'Logrosan', 'pueblo'),
    (4, 'Torrejon', 'pueblo');

-- Ubicación
INSERT INTO ubicacion (nombre_ub, id_localidad, direccion, aforo, precio_alquiler, caracteristicas) VALUES
	('Auditorio Nacional', 1, 'C/ Príncipe de Vergara, 146', 800, 3000.00, 'Gran sala de conciertos'),
	('Teatro Real', 1, 'Plaza de Isabel II, s/n', 500, 4000.00, 'Teatro histórico'),
	('Sala La Riviera', 1, 'Paseo Bajo de la Virgen del Puerto', 300, 1200.00, 'Sala de conciertos'),
	('Wizink Center', 1, 'Av. Felipe II, s/n', 1000, 8000.00, 'Pabellón multiusos'),
	('Centro Cultural', 2, 'Plaza Mayor, 1', 200, 800.00, 'Sala polivalente'),
	('Auditorio Paco de Lucía', 3, 'C/ Francia, 5', 400, 1500.00, 'Auditorio moderno'),
	('Teatro Municipal', 3, 'C/ Real, 25', 150, 600.00, 'Teatro clásico'),
	('Centro Cívico', 3, 'Av. Libertad, 10', 100, 400.00, 'Sala comunitaria'),
	('Palacio de Congresos', 4, 'C/ Castillo, 45', 600, 2500.00, 'Centro de convenciones'),
	('Sala Exposiciones', 4, 'Paseo del Arte, 8', 250, 900.00, 'Galería de arte');
    
-- Evento
INSERT INTO evento (nombre_ev, fecha, precio, descripcion, nombre_ac, nombre_ub, id_localidad) VALUES
	('Concierto Clásico Alcobendas', '2025-06-15 20:00:00', 25.00, 'Concierto de música clásica', 'VI Festival Clásica Alcobendas', 'Centro Cultural', 2),
	('Exposición Vanguardista', '2025-06-20 10:00:00', 10.00, 'Arte contemporáneo', 'Exposición Vanguardista 2025', 'Sala Exposiciones', 4),
	('Teatro La Dama de Alba', '2025-06-25 19:30:00', 20.00, 'Obra teatral clásica', 'Obra: La Dama de Alba', 'Teatro Municipal', 3),
	('Conferencia IA', '2025-07-01 18:00:00', 15.00, 'Inteligencia Artificial', 'Ciclo IA y Sociedad', 'Palacio de Congresos', 4),
	('Concierto Sinfónico', '2025-07-10 21:00:00', 35.00, 'Concierto orquestal', 'Concierto Sinfónico en Auditorio', 'Auditorio Nacional', 1),
	('Exposición Goya', '2025-07-15 11:00:00', 12.00, 'Obras maestras', 'Exposición Goya: Obras Maestras', 'Sala Exposiciones', 4),
	('Teatro Bernarda Alba', '2025-07-20 20:00:00', 18.00, 'Drama familiar', 'Teatro: La Casa de Bernarda Alba', 'Teatro Real', 1),
	('Concierto Jazz', '2025-08-05 22:00:00', 22.00, 'Jazz moderno', 'Concierto Jazz en Central', 'Sala La Riviera', 1),
	('Conferencia Sostenibilidad', '2025-08-12 17:30:00', 10.00, 'Medio ambiente', 'Conferencia Sostenibilidad', 'Centro Cívico', 3),
	('Concierto Rock', '2025-09-01 23:00:00', 28.00, 'Rock madrileño', 'Concierto Rock Madrileño', 'Wizink Center', 1);
   
-- Cuesta
INSERT INTO cuesta (nombre_ac, nombre_ar, dinero) VALUES
-- Conciertos
	('VI Festival Clásica Alcobendas', 'Orquesta Sinfónica de Madrid', 5000.00),
	('Concierto Sinfónico en Auditorio', 'Orquesta Sinfónica de Madrid', 7000.00),
	('Concierto Sinfónico en Auditorio', 'Coro Ciudad de Madrid', 2000.00),
	('Concierto Jazz en Central', 'Jazz Quartet Modern', 3000.00),
	('Concierto Jazz en Central', 'DJ Electro Sound', 1000.00),
	('Concierto Rock Madrileño', 'Banda Rock Capital', 4000.00),

-- Exposiciones
	('Exposición Vanguardista 2025', 'Pablo Vanguardista', 2500.00),
	('Exposición Vanguardista 2025', 'Ana Escultora', 1800.00),
	('Exposición Goya: Obras Maestras', 'Fundación Goya', 6000.00),
	('Exposición Fotografía Urbana', 'María Fotógrafa', 2200.00),
	('Exposición Arte Contemporáneo', 'Carlos Pintor', 2800.00),
	('Exposición Arte Contemporáneo', 'Pablo Vanguardista', 2000.00),

-- Teatro
	('Obra: La Dama de Alba', 'Teatro Contemporáneo SL', 3500.00),
	('Obra: La Dama de Alba', 'Grupo Danza Urbana', 1200.00),
	('Teatro: La Casa de Bernarda Alba', 'Compañía Teatral Clásica', 4000.00),
	('Teatro Clásico en Español', 'Compañía Teatral Clásica', 3800.00),
	('Teatro Infantil Familiar', 'Teatro Familiar Divertido', 1500.00),
	('Teatro Infantil Familiar', 'Marionetas Mágicas', 800.00),

-- Conferencias
	('Ciclo IA y Sociedad', 'Dr. Ana Tecnológica', 1200.00),
	('Conferencia Tecnología 2025', 'Dr. Ana Tecnológica', 1500.00),
	('Conferencia Tecnología 2025', 'Consultora Innovación Plus', 1800.00),
	('Conferencia Sostenibilidad', 'Prof. Carlos Sostenible', 1000.00),
	('Conferencia Innovación Empresas', 'Consultora Innovación Plus', 2000.00),
	('Conferencia Innovación Empresas', 'Dra. Laura Médica', 1300.00);

-- Asiste
INSERT INTO asiste (nombre_ev, fecha, mail, valoracion) VALUES
-- Concierto Clásico Alcobendas
	('Concierto Clásico Alcobendas', '2025-06-15 20:00:00', 'gabriel@gm.es', 5),
	('Concierto Clásico Alcobendas', '2025-06-15 20:00:00', 'helena@gm.es', 4),
	('Concierto Clásico Alcobendas', '2025-06-15 20:00:00', 'julia@gm.es', 5),

-- Exposición Vanguardista
	('Exposición Vanguardista', '2025-06-20 10:00:00', 'ivan@gm.es', 3),
	('Exposición Vanguardista', '2025-06-20 10:00:00', 'laura@gm.es', 4),
	('Exposición Vanguardista', '2025-06-20 10:00:00', 'mario@gm.es', 5),

-- Teatro La Dama de Alba
	('Teatro La Dama de Alba', '2025-06-25 19:30:00', 'nuria@gm.es', 4),
	('Teatro La Dama de Alba', '2025-06-25 19:30:00', 'oscar@gm.es', 3),
	('Teatro La Dama de Alba', '2025-06-25 19:30:00', 'patricia@gm.es', 5),

-- Conferencia IA
	('Conferencia IA', '2025-07-01 18:00:00', 'quique@gm.es', 4),
	('Conferencia IA', '2025-07-01 18:00:00', 'rosa@gm.es', 5),
	('Conferencia IA', '2025-07-01 18:00:00', 'sergio@gm.es', 4),

-- Concierto Sinfónico
	('Concierto Sinfónico', '2025-07-10 21:00:00', 'teresa@gm.es', 5),
	('Concierto Sinfónico', '2025-07-10 21:00:00', 'ulises@gm.es', 4),
	('Concierto Sinfónico', '2025-07-10 21:00:00', 'gabriel@gm.es', 5),

-- Exposición Goya
	('Exposición Goya', '2025-07-15 11:00:00', 'helena@gm.es', 5),
	('Exposición Goya', '2025-07-15 11:00:00', 'julia@gm.es', 4),

-- Teatro Bernarda Alba
	('Teatro Bernarda Alba', '2025-07-20 20:00:00', 'kiko@gm.es', 3),
	('Teatro Bernarda Alba', '2025-07-20 20:00:00', 'laura@gm.es', 5),

-- Concierto Jazz
	('Concierto Jazz', '2025-08-05 22:00:00', 'mario@gm.es', 4),
	('Concierto Jazz', '2025-08-05 22:00:00', 'nuria@gm.es', 4),

-- Conferencia Sostenibilidad
	('Conferencia Sostenibilidad', '2025-08-12 17:30:00', 'oscar@gm.es', 5),
	('Conferencia Sostenibilidad', '2025-08-12 17:30:00', 'patricia@gm.es', 4),

-- Concierto Rock
	('Concierto Rock', '2025-09-01 23:00:00', 'quique@gm.es', 5),
	('Concierto Rock', '2025-09-01 23:00:00', 'rosa@gm.es', 4),
	('Concierto Rock', '2025-09-01 23:00:00', 'sergio@gm.es', 5);


-- ========================================================================================================================
-- 4. Creación del Trigger del aforo
-- ========================================================================================================================




-- ========================================================================================================================
-- 5. Creación de vistas
-- ========================================================================================================================




-- ========================================================================================================================
-- 6. Consultas para la comprobación del modelo
-- ========================================================================================================================