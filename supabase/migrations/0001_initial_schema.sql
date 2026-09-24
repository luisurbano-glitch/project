-- ============================================================
-- SISTEMA DE CONTROLE DE PONTO ELETRÔNICO
-- PostgreSQL / Supabase
-- Schema inicial completo
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- ============================================================
-- ENUMS
-- ============================================================

DO $$
BEGIN
    CREATE TYPE public.user_role AS ENUM (
        'admin',
        'rh',
        'gestor',
        'operador',
        'funcionario'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;


DO $$
BEGIN
    CREATE TYPE public.employee_status AS ENUM (
        'ativo',
        'inativo',
        'afastado',
        'ferias',
        'desligado'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;


DO $$
BEGIN
    CREATE TYPE public.attendance_event_type AS ENUM (
        'entrada',
        'inicio_intervalo',
        'fim_intervalo',
        'saida'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;


DO $$
BEGIN
    CREATE TYPE public.authentication_method AS ENUM (
        'pin',
        'rfid',
        'camera',
        'webauthn',
        'biometria_externa',
        'administrativo'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;


DO $$
BEGIN
    CREATE TYPE public.network_status AS ENUM (
        'online',
        'offline'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;


DO $$
BEGIN
    CREATE TYPE public.sync_status AS ENUM (
        'local',
        'pendente',
        'sincronizado',
        'erro'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;


DO $$
BEGIN
    CREATE TYPE public.inconsistency_type AS ENUM (
        'atraso',
        'saida_antecipada',
        'intervalo_irregular',
        'falta',
        'marcacao_duplicada',
        'marcacao_invalida',
        'jornada_incompleta',
        'outro'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;


DO $$
BEGIN
    CREATE TYPE public.inconsistency_status AS ENUM (
        'aberta',
        'justificada',
        'abonada',
        'rejeitada',
        'resolvida'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;


DO $$
BEGIN
    CREATE TYPE public.justification_status AS ENUM (
        'pendente',
        'enviada',
        'aprovada',
        'rejeitada'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;


DO $$
BEGIN
    CREATE TYPE public.document_status AS ENUM (
        'pendente',
        'aprovado',
        'rejeitado',
        'cancelado'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;


DO $$
BEGIN
    CREATE TYPE public.absence_type AS ENUM (
        'folga',
        'ferias',
        'afastamento',
        'feriado',
        'falta_justificada',
        'falta_injustificada',
        'abono'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;


DO $$
BEGIN
    CREATE TYPE public.receipt_delivery_status AS ENUM (
        'pendente',
        'impresso',
        'enviado',
        'erro'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;


-- ============================================================
-- EMPRESAS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    legal_name TEXT NOT NULL,
    trade_name TEXT,

    cnpj VARCHAR(18) NOT NULL UNIQUE,

    address_line TEXT,
    address_number TEXT,
    address_complement TEXT,
    neighborhood TEXT,
    city TEXT,
    state VARCHAR(2),
    postal_code VARCHAR(9),

    timezone TEXT NOT NULL DEFAULT 'America/Sao_Paulo',

    event_tolerance_minutes INTEGER NOT NULL DEFAULT 5,
    daily_tolerance_minutes INTEGER NOT NULL DEFAULT 10,

    active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT companies_event_tolerance_check
        CHECK (event_tolerance_minutes >= 0),

    CONSTRAINT companies_daily_tolerance_check
        CHECK (daily_tolerance_minutes >= 0)
);


-- ============================================================
-- CARGOS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES public.companies(id)
        ON DELETE RESTRICT,

    name TEXT NOT NULL,
    description TEXT,

    active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(company_id, name)
);


-- ============================================================
-- JORNADAS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.work_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES public.companies(id)
        ON DELETE RESTRICT,

    name TEXT NOT NULL,

    monday_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    tuesday_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    wednesday_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    thursday_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    friday_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    saturday_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    sunday_enabled BOOLEAN NOT NULL DEFAULT FALSE,

    expected_start TIME,
    expected_break_start TIME,
    expected_break_end TIME,
    expected_end TIME,

    expected_daily_minutes INTEGER,

    overnight BOOLEAN NOT NULL DEFAULT FALSE,

    active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT work_schedule_daily_minutes_check
        CHECK (
            expected_daily_minutes IS NULL
            OR expected_daily_minutes >= 0
        )
);


-- ============================================================
-- FUNCIONÁRIOS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES public.companies(id)
        ON DELETE RESTRICT,

    position_id UUID
        REFERENCES public.positions(id)
        ON DELETE SET NULL,

    work_schedule_id UUID
        REFERENCES public.work_schedules(id)
        ON DELETE SET NULL,

    employee_code TEXT NOT NULL,

    full_name TEXT NOT NULL,

    pis TEXT,
    cpf TEXT,
    email TEXT,
    phone TEXT,

    hire_date DATE,
    termination_date DATE,

    status public.employee_status NOT NULL DEFAULT 'ativo',

    pin_hash TEXT,

    rfid_identifier TEXT,

    photo_storage_path TEXT,

    biometric_reference TEXT,

    biometric_enabled BOOLEAN NOT NULL DEFAULT FALSE,

    active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(company_id, employee_code)
);


CREATE UNIQUE INDEX IF NOT EXISTS employees_rfid_unique
ON public.employees(company_id, rfid_identifier)
WHERE rfid_identifier IS NOT NULL;


CREATE INDEX IF NOT EXISTS employees_company_idx
ON public.employees(company_id);


CREATE INDEX IF NOT EXISTS employees_status_idx
ON public.employees(company_id, status);


-- ============================================================
-- PERFIS DE USUÁRIO
-- ============================================================

CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY
        REFERENCES auth.users(id)
        ON DELETE CASCADE,

    company_id UUID
        REFERENCES public.companies(id)
        ON DELETE RESTRICT,

    employee_id UUID
        REFERENCES public.employees(id)
        ON DELETE SET NULL,

    full_name TEXT NOT NULL,

    role public.user_role NOT NULL,

    active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


CREATE INDEX IF NOT EXISTS user_profiles_company_idx
ON public.user_profiles(company_id);


-- ============================================================
-- RELAÇÃO GESTOR / FUNCIONÁRIO
-- ============================================================

CREATE TABLE IF NOT EXISTS public.manager_employees (
    manager_user_id UUID NOT NULL
        REFERENCES public.user_profiles(id)
        ON DELETE CASCADE,

    employee_id UUID NOT NULL
        REFERENCES public.employees(id)
        ON DELETE CASCADE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (manager_user_id, employee_id)
);


-- ============================================================
-- TERMINAIS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.terminals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES public.companies(id)
        ON DELETE RESTRICT,

    terminal_code TEXT NOT NULL,
    name TEXT NOT NULL,

    location_description TEXT,

    active BOOLEAN NOT NULL DEFAULT TRUE,

    printer_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    camera_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    rfid_enabled BOOLEAN NOT NULL DEFAULT FALSE,

    last_seen_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(company_id, terminal_code)
);


-- ============================================================
-- FERIADOS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.holidays (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID
        REFERENCES public.companies(id)
        ON DELETE CASCADE,

    holiday_date DATE NOT NULL,

    name TEXT NOT NULL,

    national BOOLEAN NOT NULL DEFAULT FALSE,

    active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(company_id, holiday_date)
);


-- ============================================================
-- AUSÊNCIAS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.employee_absences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    employee_id UUID NOT NULL
        REFERENCES public.employees(id)
        ON DELETE RESTRICT,

    absence_type public.absence_type NOT NULL,

    start_date DATE NOT NULL,
    end_date DATE NOT NULL,

    reason TEXT,

    approved_by UUID
        REFERENCES public.user_profiles(id)
        ON DELETE SET NULL,

    approved_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT employee_absences_dates_check
        CHECK (end_date >= start_date)
);


CREATE INDEX IF NOT EXISTS employee_absences_employee_date_idx
ON public.employee_absences(
    employee_id,
    start_date,
    end_date
);


-- ============================================================
-- MARCAÇÕES DE PONTO
--
-- IMPORTANTE:
-- Esta tabela deve ser APPEND-ONLY.
-- Não alterar nem apagar marcações.
-- Correções ficam em attendance_adjustments.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.attendance_records (

    id UUID PRIMARY KEY,

    employee_id UUID NOT NULL
        REFERENCES public.employees(id)
        ON DELETE RESTRICT,

    company_id UUID NOT NULL
        REFERENCES public.companies(id)
        ON DELETE RESTRICT,

    terminal_id UUID
        REFERENCES public.terminals(id)
        ON DELETE SET NULL,

    event_type public.attendance_event_type NOT NULL,

    authentication_method public.authentication_method NOT NULL,

    network_status public.network_status NOT NULL,

    sync_status public.sync_status NOT NULL DEFAULT 'sincronizado',

    client_recorded_at TIMESTAMPTZ NOT NULL,

    server_recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    timezone TEXT NOT NULL DEFAULT 'America/Sao_Paulo',

    photo_storage_path TEXT,

    credential_reference TEXT,

    client_device_id TEXT,

    integrity_hash TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    metadata JSONB NOT NULL DEFAULT '{}'::JSONB
);


CREATE INDEX IF NOT EXISTS attendance_employee_date_idx
ON public.attendance_records(
    employee_id,
    server_recorded_at
);


CREATE INDEX IF NOT EXISTS attendance_company_date_idx
ON public.attendance_records(
    company_id,
    server_recorded_at
);


CREATE INDEX IF NOT EXISTS attendance_terminal_idx
ON public.attendance_records(terminal_id);


CREATE INDEX IF NOT EXISTS attendance_sync_status_idx
ON public.attendance_records(sync_status);


-- ============================================================
-- JUSTIFICATIVAS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.justifications (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    employee_id UUID NOT NULL
        REFERENCES public.employees(id)
        ON DELETE RESTRICT,

    attendance_record_id UUID
        REFERENCES public.attendance_records(id)
        ON DELETE RESTRICT,

    text TEXT NOT NULL,

    status public.justification_status
        NOT NULL DEFAULT 'pendente',

    submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    reviewed_by UUID
        REFERENCES public.user_profiles(id)
        ON DELETE SET NULL,

    reviewed_at TIMESTAMPTZ,

    review_comment TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- INCONSISTÊNCIAS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.attendance_inconsistencies (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES public.companies(id)
        ON DELETE RESTRICT,

    employee_id UUID NOT NULL
        REFERENCES public.employees(id)
        ON DELETE RESTRICT,

    attendance_record_id UUID
        REFERENCES public.attendance_records(id)
        ON DELETE RESTRICT,

    inconsistency_type public.inconsistency_type NOT NULL,

    reference_date DATE NOT NULL,

    minutes INTEGER NOT NULL DEFAULT 0,

    description TEXT,

    status public.inconsistency_status
        NOT NULL DEFAULT 'aberta',

    justification_id UUID
        REFERENCES public.justifications(id)
        ON DELETE SET NULL,

    resolved_by UUID
        REFERENCES public.user_profiles(id)
        ON DELETE SET NULL,

    resolved_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


CREATE INDEX IF NOT EXISTS inconsistencies_employee_date_idx
ON public.attendance_inconsistencies(
    employee_id,
    reference_date
);


CREATE INDEX IF NOT EXISTS inconsistencies_open_idx
ON public.attendance_inconsistencies(
    company_id,
    status
)
WHERE status = 'aberta';


-- ============================================================
-- ATESTADOS MÉDICOS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.medical_documents (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    employee_id UUID NOT NULL
        REFERENCES public.employees(id)
        ON DELETE RESTRICT,

    uploaded_by UUID
        REFERENCES public.user_profiles(id)
        ON DELETE SET NULL,

    storage_path TEXT NOT NULL,

    original_filename TEXT,

    mime_type TEXT,

    file_size BIGINT,

    document_date DATE,

    start_date DATE,

    end_date DATE,

    description TEXT,

    status public.document_status
        NOT NULL DEFAULT 'pendente',

    reviewed_by UUID
        REFERENCES public.user_profiles(id)
        ON DELETE SET NULL,

    reviewed_at TIMESTAMPTZ,

    review_comment TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT medical_documents_dates_check
        CHECK (
            end_date IS NULL
            OR start_date IS NULL
            OR end_date >= start_date
        )
);


CREATE INDEX IF NOT EXISTS medical_documents_employee_idx
ON public.medical_documents(employee_id);


-- ============================================================
-- ABONOS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.attendance_excuses (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    employee_id UUID NOT NULL
        REFERENCES public.employees(id)
        ON DELETE RESTRICT,

    medical_document_id UUID
        REFERENCES public.medical_documents(id)
        ON DELETE SET NULL,

    inconsistency_id UUID
        REFERENCES public.attendance_inconsistencies(id)
        ON DELETE SET NULL,

    attendance_date DATE NOT NULL,

    minutes INTEGER NOT NULL DEFAULT 0,

    reason TEXT,

    approved_by UUID
        REFERENCES public.user_profiles(id)
        ON DELETE SET NULL,

    approved_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- REGISTRO DE FALTAS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.employee_absence_records (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES public.companies(id)
        ON DELETE RESTRICT,

    employee_id UUID NOT NULL
        REFERENCES public.employees(id)
        ON DELETE RESTRICT,

    reference_date DATE NOT NULL,

    absence_type public.absence_type NOT NULL,

    automatically_generated BOOLEAN NOT NULL DEFAULT FALSE,

    justification_id UUID
        REFERENCES public.justifications(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(employee_id, reference_date)
);


-- ============================================================
-- AJUSTES ADMINISTRATIVOS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.attendance_adjustments (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    attendance_record_id UUID
        REFERENCES public.attendance_records(id)
        ON DELETE RESTRICT,

    employee_id UUID NOT NULL
        REFERENCES public.employees(id)
        ON DELETE RESTRICT,

    created_by UUID NOT NULL
        REFERENCES public.user_profiles(id)
        ON DELETE RESTRICT,

    adjustment_type TEXT NOT NULL,

    original_value JSONB,

    new_value JSONB,

    reason TEXT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- AUDITORIA
-- ============================================================

CREATE TABLE IF NOT EXISTS public.audit_logs (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID
        REFERENCES public.companies(id)
        ON DELETE SET NULL,

    actor_user_id UUID
        REFERENCES public.user_profiles(id)
        ON DELETE SET NULL,

    actor_employee_id UUID
        REFERENCES public.employees(id)
        ON DELETE SET NULL,

    action TEXT NOT NULL,

    entity_type TEXT,

    entity_id UUID,

    old_data JSONB,

    new_data JSONB,

    ip_address INET,

    user_agent TEXT,

    client_timestamp TIMESTAMPTZ,

    server_timestamp TIMESTAMPTZ
        NOT NULL DEFAULT NOW(),

    metadata JSONB NOT NULL DEFAULT '{}'::JSONB
);


CREATE INDEX IF NOT EXISTS audit_company_date_idx
ON public.audit_logs(
    company_id,
    server_timestamp
);


CREATE INDEX IF NOT EXISTS audit_entity_idx
ON public.audit_logs(
    entity_type,
    entity_id
);


-- ============================================================
-- COMPROVANTES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.receipt_deliveries (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    attendance_record_id UUID NOT NULL
        REFERENCES public.attendance_records(id)
        ON DELETE RESTRICT,

    employee_id UUID NOT NULL
        REFERENCES public.employees(id)
        ON DELETE RESTRICT,

    delivery_type TEXT NOT NULL,

    status public.receipt_delivery_status
        NOT NULL DEFAULT 'pendente',

    destination TEXT,

    attempted_at TIMESTAMPTZ,

    completed_at TIMESTAMPTZ,

    error_message TEXT,

    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT receipt_delivery_type_check
        CHECK (
            delivery_type IN (
                'impressao',
                'email'
            )
        )
);


-- ============================================================
-- CONFIGURAÇÕES DA EMPRESA
-- ============================================================

CREATE TABLE IF NOT EXISTS public.company_settings (

    company_id UUID PRIMARY KEY
        REFERENCES public.companies(id)
        ON DELETE CASCADE,

    require_photo BOOLEAN NOT NULL DEFAULT TRUE,

    allow_pin BOOLEAN NOT NULL DEFAULT TRUE,

    allow_rfid BOOLEAN NOT NULL DEFAULT TRUE,

    allow_camera BOOLEAN NOT NULL DEFAULT TRUE,

    allow_offline_attendance BOOLEAN NOT NULL DEFAULT TRUE,

    require_justification_outside_tolerance
        BOOLEAN NOT NULL DEFAULT TRUE,

    auto_email_receipt_on_printer_failure
        BOOLEAN NOT NULL DEFAULT TRUE,

    attendance_duplicate_window_seconds
        INTEGER NOT NULL DEFAULT 60,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT duplicate_window_check
        CHECK (
            attendance_duplicate_window_seconds >= 0
        )
);


-- ============================================================
-- FUNÇÃO updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


-- ============================================================
-- TRIGGERS updated_at
-- ============================================================

DROP TRIGGER IF EXISTS companies_updated_at
ON public.companies;

CREATE TRIGGER companies_updated_at
BEFORE UPDATE ON public.companies
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();


DROP TRIGGER IF EXISTS positions_updated_at
ON public.positions;

CREATE TRIGGER positions_updated_at
BEFORE UPDATE ON public.positions
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();


DROP TRIGGER IF EXISTS work_schedules_updated_at
ON public.work_schedules;

CREATE TRIGGER work_schedules_updated_at
BEFORE UPDATE ON public.work_schedules
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();


DROP TRIGGER IF EXISTS employees_updated_at
ON public.employees;

CREATE TRIGGER employees_updated_at
BEFORE UPDATE ON public.employees
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();


DROP TRIGGER IF EXISTS user_profiles_updated_at
ON public.user_profiles;

CREATE TRIGGER user_profiles_updated_at
BEFORE UPDATE ON public.user_profiles
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();


DROP TRIGGER IF EXISTS terminals_updated_at
ON public.terminals;

CREATE TRIGGER terminals_updated_at
BEFORE UPDATE ON public.terminals
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();


DROP TRIGGER IF EXISTS company_settings_updated_at
ON public.company_settings;

CREATE TRIGGER company_settings_updated_at
BEFORE UPDATE ON public.company_settings
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();


-- ============================================================
-- PROTEÇÃO DA TABELA DE MARCAÇÕES
--
-- UPDATE/DELETE são proibidos.
-- ============================================================

CREATE OR REPLACE FUNCTION public.prevent_attendance_mutation()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    RAISE EXCEPTION
        'Marcação de ponto é imutável. Utilize attendance_adjustments.';
END;
$$;


DROP TRIGGER IF EXISTS prevent_attendance_update
ON public.attendance_records;

CREATE TRIGGER prevent_attendance_update
BEFORE UPDATE ON public.attendance_records
FOR EACH ROW
EXECUTE FUNCTION public.prevent_attendance_mutation();


DROP TRIGGER IF EXISTS prevent_attendance_delete
ON public.attendance_records;

CREATE TRIGGER prevent_attendance_delete
BEFORE DELETE ON public.attendance_records
FOR EACH ROW
EXECUTE FUNCTION public.prevent_attendance_mutation();


-- ============================================================
-- HASH DE INTEGRIDADE DA MARCAÇÃO
-- ============================================================

CREATE OR REPLACE FUNCTION public.generate_attendance_integrity_hash()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN

    NEW.integrity_hash :=
        ENCODE(
            DIGEST(
                CONCAT_WS(
                    '|',
                    NEW.id::TEXT,
                    NEW.employee_id::TEXT,
                    NEW.company_id::TEXT,
                    NEW.event_type::TEXT,
                    NEW.authentication_method::TEXT,
                    NEW.client_recorded_at::TEXT,
                    NEW.server_recorded_at::TEXT,
                    COALESCE(NEW.terminal_id::TEXT, ''),
                    COALESCE(NEW.client_device_id, '')
                ),
                'sha256'
            ),
            'hex'
        );

    RETURN NEW;

END;
$$;


DROP TRIGGER IF EXISTS attendance_integrity_hash
ON public.attendance_records;

CREATE TRIGGER attendance_integrity_hash
BEFORE INSERT ON public.attendance_records
FOR EACH ROW
EXECUTE FUNCTION public.generate_attendance_integrity_hash();


-- ============================================================
-- FUNÇÕES DO USUÁRIO LOGADO
-- ============================================================

CREATE OR REPLACE FUNCTION public.current_company_id()
RETURNS UUID
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT company_id
    FROM public.user_profiles
    WHERE id = auth.uid()
    LIMIT 1;
$$;


CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS public.user_role
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT role
    FROM public.user_profiles
    WHERE id = auth.uid()
    LIMIT 1;
$$;


-- ============================================================
-- RLS
-- ============================================================

ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.work_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.manager_employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.terminals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.holidays ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_absences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.justifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_inconsistencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medical_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_excuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_absence_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipt_deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_settings ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- EMPRESAS
-- ============================================================

DROP POLICY IF EXISTS companies_select_same_company
ON public.companies;

CREATE POLICY companies_select_same_company
ON public.companies
FOR SELECT
TO authenticated
USING (
    id = public.current_company_id()
);


-- ============================================================
-- FUNCIONÁRIOS
-- ============================================================

DROP POLICY IF EXISTS employees_select_same_company
ON public.employees;

CREATE POLICY employees_select_same_company
ON public.employees
FOR SELECT
TO authenticated
USING (
    company_id = public.current_company_id()
);


DROP POLICY IF EXISTS employees_manage_rh_admin
ON public.employees;

CREATE POLICY employees_manage_rh_admin
ON public.employees
FOR ALL
TO authenticated
USING (
    company_id = public.current_company_id()
    AND public.current_user_role() IN ('admin', 'rh')
)
WITH CHECK (
    company_id = public.current_company_id()
    AND public.current_user_role() IN ('admin', 'rh')
);


-- ============================================================
-- CARGOS
-- ============================================================

DROP POLICY IF EXISTS positions_select_same_company
ON public.positions;

CREATE POLICY positions_select_same_company
ON public.positions
FOR SELECT
TO authenticated
USING (
    company_id = public.current_company_id()
);


DROP POLICY IF EXISTS positions_manage_admin_rh
ON public.positions;

CREATE POLICY positions_manage_admin_rh
ON public.positions
FOR ALL
TO authenticated
USING (
    company_id = public.current_company_id()
    AND public.current_user_role() IN ('admin', 'rh')
)
WITH CHECK (
    company_id = public.current_company_id()
    AND public.current_user_role() IN ('admin', 'rh')
);


-- ============================================================
-- JORNADAS
-- ============================================================

DROP POLICY IF EXISTS work_schedules_select_same_company
ON public.work_schedules;

CREATE POLICY work_schedules_select_same_company
ON public.work_schedules
FOR SELECT
TO authenticated
USING (
    company_id = public.current_company_id()
);


DROP POLICY IF EXISTS work_schedules_manage_admin_rh
ON public.work_schedules;

CREATE POLICY work_schedules_manage_admin_rh
ON public.work_schedules
FOR ALL
TO authenticated
USING (
    company_id = public.current_company_id()
    AND public.current_user_role() IN ('admin', 'rh')
)
WITH CHECK (
    company_id = public.current_company_id()
    AND public.current_user_role() IN ('admin', 'rh')
);


-- ============================================================
-- TERMINAIS
-- ============================================================

DROP POLICY IF EXISTS terminals_select_same_company
ON public.terminals;

CREATE POLICY terminals_select_same_company
ON public.terminals
FOR SELECT
TO authenticated
USING (
    company_id = public.current_company_id()
);


DROP POLICY IF EXISTS terminals_manage_admin
ON public.terminals;

CREATE POLICY terminals_manage_admin
ON public.terminals
FOR ALL
TO authenticated
USING (
    company_id = public.current_company_id()
    AND public.current_user_role() = 'admin'
)
WITH CHECK (
    company_id = public.current_company_id()
    AND public.current_user_role() = 'admin'
);


-- ============================================================
-- MARCAÇÕES
-- ============================================================

DROP POLICY IF EXISTS attendance_select_same_company
ON public.attendance_records;

CREATE POLICY attendance_select_same_company
ON public.attendance_records
FOR SELECT
TO authenticated
USING (
    company_id = public.current_company_id()
);


DROP POLICY IF EXISTS attendance_insert_same_company
ON public.attendance_records;

CREATE POLICY attendance_insert_same_company
ON public.attendance_records
FOR INSERT
TO authenticated
WITH CHECK (
    company_id = public.current_company_id()
);


-- ============================================================
-- INCONSISTÊNCIAS
-- ============================================================

DROP POLICY IF EXISTS inconsistencies_select_same_company
ON public.attendance_inconsistencies;

CREATE POLICY inconsistencies_select_same_company
ON public.attendance_inconsistencies
FOR SELECT
TO authenticated
USING (
    company_id = public.current_company_id()
);


DROP POLICY IF EXISTS inconsistencies_manage
ON public.attendance_inconsistencies;

CREATE POLICY inconsistencies_manage
ON public.attendance_inconsistencies
FOR ALL
TO authenticated
USING (
    company_id = public.current_company_id()
    AND public.current_user_role() IN (
        'admin',
        'rh',
        'gestor'
    )
)
WITH CHECK (
    company_id = public.current_company_id()
    AND public.current_user_role() IN (
        'admin',
        'rh',
        'gestor'
    )
);


-- ============================================================
-- JUSTIFICATIVAS
-- ============================================================

DROP POLICY IF EXISTS justifications_select_same_company
ON public.justifications;

CREATE POLICY justifications_select_same_company
ON public.justifications
FOR SELECT
TO authenticated
USING (
    employee_id IN (
        SELECT id
        FROM public.employees
        WHERE company_id = public.current_company_id()
    )
);


DROP POLICY IF EXISTS justifications_insert
ON public.justifications;

CREATE POLICY justifications_insert
ON public.justifications
FOR INSERT
TO authenticated
WITH CHECK (
    employee_id IN (
        SELECT id
        FROM public.employees
        WHERE company_id = public.current_company_id()
    )
);


DROP POLICY IF EXISTS justifications_manage
ON public.justifications;

CREATE POLICY justifications_manage
ON public.justifications
FOR UPDATE
TO authenticated
USING (
    public.current_user_role() IN (
        'admin',
        'rh',
        'gestor'
    )
    AND employee_id IN (
        SELECT id
        FROM public.employees
        WHERE company_id = public.current_company_id()
    )
);


-- ============================================================
-- ATESTADOS
-- ============================================================

DROP POLICY IF EXISTS medical_documents_select
ON public.medical_documents;

CREATE POLICY medical_documents_select
ON public.medical_documents
FOR SELECT
TO authenticated
USING (
    employee_id IN (
        SELECT id
        FROM public.employees
        WHERE company_id = public.current_company_id()
    )
);


DROP POLICY IF EXISTS medical_documents_insert
ON public.medical_documents;

CREATE POLICY medical_documents_insert
ON public.medical_documents
FOR INSERT
TO authenticated
WITH CHECK (
    employee_id IN (
        SELECT id
        FROM public.employees
        WHERE company_id = public.current_company_id()
    )
);


DROP POLICY IF EXISTS medical_documents_manage
ON public.medical_documents;

CREATE POLICY medical_documents_manage
ON public.medical_documents
FOR UPDATE
TO authenticated
USING (
    public.current_user_role() IN ('admin', 'rh')
);


-- ============================================================
-- AUDITORIA
-- ============================================================

DROP POLICY IF EXISTS audit_select_admin_rh
ON public.audit_logs;

CREATE POLICY audit_select_admin_rh
ON public.audit_logs
FOR SELECT
TO authenticated
USING (
    company_id = public.current_company_id()
    AND public.current_user_role() IN ('admin', 'rh')
);


-- ============================================================
-- PERFIL
-- ============================================================

DROP POLICY IF EXISTS user_profile_select_self
ON public.user_profiles;

CREATE POLICY user_profile_select_self
ON public.user_profiles
FOR SELECT
TO authenticated
USING (
    id = auth.uid()
);


-- ============================================================
-- CONFIGURAÇÕES
-- ============================================================

DROP POLICY IF EXISTS company_settings_select
ON public.company_settings;

CREATE POLICY company_settings_select
ON public.company_settings
FOR SELECT
TO authenticated
USING (
    company_id = public.current_company_id()
);


DROP POLICY IF EXISTS company_settings_manage
ON public.company_settings;

CREATE POLICY company_settings_manage
ON public.company_settings
FOR ALL
TO authenticated
USING (
    company_id = public.current_company_id()
    AND public.current_user_role() = 'admin'
)
WITH CHECK (
    company_id = public.current_company_id()
    AND public.current_user_role() = 'admin'
);


-- ============================================================
-- VIEWS
-- ============================================================

CREATE OR REPLACE VIEW public.active_employees
WITH (security_invoker = true)
AS
SELECT
    e.*
FROM public.employees e
WHERE
    e.active = TRUE
    AND e.status = 'ativo';


CREATE OR REPLACE VIEW public.open_inconsistencies
WITH (security_invoker = true)
AS
SELECT
    i.id,
    i.company_id,
    i.employee_id,
    e.employee_code,
    e.full_name,
    i.inconsistency_type,
    i.reference_date,
    i.minutes,
    i.description,
    i.status,
    i.created_at
FROM public.attendance_inconsistencies i
JOIN public.employees e
    ON e.id = i.employee_id
WHERE
    i.status = 'aberta';


-- ============================================================
-- FIM
-- ============================================================
