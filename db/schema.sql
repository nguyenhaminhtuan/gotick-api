\restrict dbmate

-- Dumped from database version 18.4 (Debian 18.4-1.pgdg13+1)
-- Dumped by pg_dump version 18.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    id uuid DEFAULT uuidv7() NOT NULL,
    full_name text NOT NULL,
    email text NOT NULL,
    avatar text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    suspended_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT accounts_status_check CHECK ((status = ANY (ARRAY['active'::text, 'suspended'::text])))
);


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id smallint NOT NULL,
    name text NOT NULL,
    slug character varying(60) NOT NULL,
    icon text,
    display_order smallint DEFAULT 0 NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT categories_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text])))
);


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.categories ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cities (
    code character varying(20) NOT NULL,
    name text NOT NULL,
    name_en text,
    full_name text NOT NULL,
    full_name_en text,
    status text DEFAULT 'active'::text NOT NULL,
    CONSTRAINT cities_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text])))
);


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    id uuid DEFAULT uuidv7() NOT NULL,
    organizer_id uuid NOT NULL,
    category_id smallint,
    name text NOT NULL,
    slug character varying(60) NOT NULL,
    description text NOT NULL,
    image text NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    is_listed boolean DEFAULT true NOT NULL,
    is_featured boolean DEFAULT false NOT NULL,
    published_at timestamp with time zone,
    closed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT events_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'published'::text, 'closed'::text])))
);


--
-- Name: occurrences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.occurrences (
    id uuid DEFAULT uuidv7() NOT NULL,
    event_id uuid NOT NULL,
    name text NOT NULL,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL,
    venue_name text NOT NULL,
    venue_address text NOT NULL,
    venue_city_code character varying(20),
    status text DEFAULT 'scheduled'::text NOT NULL,
    waiting_room_enabled boolean DEFAULT false NOT NULL,
    canceled_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT occurrences_status_check CHECK ((status = ANY (ARRAY['scheduled'::text, 'canceled'::text, 'postponed'::text])))
);


--
-- Name: order_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_items (
    id uuid DEFAULT uuidv7() NOT NULL,
    order_id uuid NOT NULL,
    ticket_category_id uuid NOT NULL,
    quantity integer NOT NULL,
    unit_price bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT order_items_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT order_items_unit_price_check CHECK ((unit_price >= 0))
);


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders (
    id uuid DEFAULT uuidv7() NOT NULL,
    customer_id uuid NOT NULL,
    occurrence_id uuid NOT NULL,
    total_amount bigint NOT NULL,
    status text DEFAULT 'pending_payment'::text NOT NULL,
    hold_expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT orders_status_check CHECK ((status = ANY (ARRAY['pending_payment'::text, 'paid'::text, 'canceled'::text, 'expired'::text]))),
    CONSTRAINT orders_total_amount_check CHECK ((total_amount > 0))
);


--
-- Name: organizer_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizer_applications (
    id uuid DEFAULT uuidv7() NOT NULL,
    organizer_id uuid NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    review_note text DEFAULT ''::text NOT NULL,
    reviewed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT organizer_applications_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'changes_requested'::text, 'rejected'::text])))
);


--
-- Name: organizer_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizer_members (
    organizer_id uuid NOT NULL,
    account_id uuid NOT NULL,
    role text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT organizer_members_role_check CHECK ((role = ANY (ARRAY['owner'::text, 'staff'::text])))
);


--
-- Name: organizers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizers (
    id uuid DEFAULT uuidv7() NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    organizer_type text NOT NULL,
    logo text NOT NULL,
    email text NOT NULL,
    phone text NOT NULL,
    public_contact jsonb DEFAULT '{}'::jsonb NOT NULL,
    status text DEFAULT 'pending_registration'::text NOT NULL,
    activated_at timestamp with time zone,
    suspended_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT organizers_organizer_type_check CHECK ((organizer_type = ANY (ARRAY['individual'::text, 'organization'::text]))),
    CONSTRAINT organizers_status_check CHECK ((status = ANY (ARRAY['pending_registration'::text, 'active'::text, 'suspended'::text])))
);


--
-- Name: platform_staff; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platform_staff (
    account_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: sale_phase_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sale_phase_categories (
    sale_phase_id uuid NOT NULL,
    ticket_category_id uuid NOT NULL
);


--
-- Name: sale_phases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sale_phases (
    id uuid DEFAULT uuidv7() NOT NULL,
    occurrence_id uuid NOT NULL,
    name text NOT NULL,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL,
    max_buy_per_customer integer NOT NULL,
    status text DEFAULT 'coming_soon'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT sale_phases_status_check CHECK ((status = ANY (ARRAY['coming_soon'::text, 'on_sale'::text, 'suspended'::text, 'ended'::text, 'canceled'::text])))
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: ticket_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ticket_categories (
    id uuid DEFAULT uuidv7() NOT NULL,
    occurrence_id uuid NOT NULL,
    name text NOT NULL,
    zone text DEFAULT ''::text NOT NULL,
    price bigint NOT NULL,
    quantity integer NOT NULL,
    priority integer NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    max_buy_per_customer integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tickets (
    id uuid DEFAULT uuidv7() NOT NULL,
    order_item_id uuid NOT NULL,
    event_id uuid NOT NULL,
    occurrence_id uuid NOT NULL,
    ticket_category_id uuid NOT NULL,
    qr_code text NOT NULL,
    status text DEFAULT 'reserved'::text NOT NULL,
    issued_at timestamp with time zone DEFAULT now() NOT NULL,
    used_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT tickets_status_check CHECK ((status = ANY (ARRAY['reserved'::text, 'valid'::text, 'checked_in'::text, 'voided'::text, 'refunded'::text])))
);


--
-- Name: accounts accounts_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_email_key UNIQUE (email);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: categories categories_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_slug_key UNIQUE (slug);


--
-- Name: cities cities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cities
    ADD CONSTRAINT cities_pkey PRIMARY KEY (code);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: events events_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_slug_key UNIQUE (slug);


--
-- Name: occurrences occurrences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrences
    ADD CONSTRAINT occurrences_pkey PRIMARY KEY (id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: organizer_applications organizer_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizer_applications
    ADD CONSTRAINT organizer_applications_pkey PRIMARY KEY (id);


--
-- Name: organizer_members organizer_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizer_members
    ADD CONSTRAINT organizer_members_pkey PRIMARY KEY (organizer_id, account_id);


--
-- Name: organizers organizers_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizers
    ADD CONSTRAINT organizers_email_key UNIQUE (email);


--
-- Name: organizers organizers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizers
    ADD CONSTRAINT organizers_pkey PRIMARY KEY (id);


--
-- Name: platform_staff platform_staff_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_staff
    ADD CONSTRAINT platform_staff_pkey PRIMARY KEY (account_id);


--
-- Name: sale_phase_categories sale_phase_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_phase_categories
    ADD CONSTRAINT sale_phase_categories_pkey PRIMARY KEY (sale_phase_id, ticket_category_id);


--
-- Name: sale_phases sale_phases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_phases
    ADD CONSTRAINT sale_phases_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: ticket_categories ticket_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_categories
    ADD CONSTRAINT ticket_categories_pkey PRIMARY KEY (id);


--
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


--
-- Name: tickets tickets_qr_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_qr_code_key UNIQUE (qr_code);


--
-- Name: events_category_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_category_id_idx ON public.events USING btree (category_id);


--
-- Name: events_organizer_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_organizer_id_idx ON public.events USING btree (organizer_id);


--
-- Name: occurrences_event_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX occurrences_event_id_idx ON public.occurrences USING btree (event_id);


--
-- Name: order_items_order_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX order_items_order_id_idx ON public.order_items USING btree (order_id);


--
-- Name: order_items_ticket_category_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX order_items_ticket_category_id_idx ON public.order_items USING btree (ticket_category_id);


--
-- Name: orders_customer_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orders_customer_id_idx ON public.orders USING btree (customer_id);


--
-- Name: orders_occurrence_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orders_occurrence_id_idx ON public.orders USING btree (occurrence_id);


--
-- Name: organizer_applications_organizer_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX organizer_applications_organizer_id_idx ON public.organizer_applications USING btree (organizer_id);


--
-- Name: organizer_members_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX organizer_members_account_id_idx ON public.organizer_members USING btree (account_id);


--
-- Name: sale_phase_categories_ticket_category_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sale_phase_categories_ticket_category_id_idx ON public.sale_phase_categories USING btree (ticket_category_id);


--
-- Name: sale_phases_occurrence_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sale_phases_occurrence_id_idx ON public.sale_phases USING btree (occurrence_id);


--
-- Name: ticket_categories_occurrence_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ticket_categories_occurrence_id_idx ON public.ticket_categories USING btree (occurrence_id);


--
-- Name: tickets_order_item_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tickets_order_item_id_idx ON public.tickets USING btree (order_item_id);


--
-- Name: events events_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: events events_organizer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_organizer_id_fkey FOREIGN KEY (organizer_id) REFERENCES public.organizers(id) ON DELETE CASCADE;


--
-- Name: occurrences occurrences_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrences
    ADD CONSTRAINT occurrences_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: occurrences occurrences_venue_city_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrences
    ADD CONSTRAINT occurrences_venue_city_code_fkey FOREIGN KEY (venue_city_code) REFERENCES public.cities(code) ON DELETE SET NULL;


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: order_items order_items_ticket_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_ticket_category_id_fkey FOREIGN KEY (ticket_category_id) REFERENCES public.ticket_categories(id) ON DELETE RESTRICT;


--
-- Name: orders orders_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.accounts(id);


--
-- Name: orders orders_occurrence_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_occurrence_id_fkey FOREIGN KEY (occurrence_id) REFERENCES public.occurrences(id);


--
-- Name: organizer_applications organizer_applications_organizer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizer_applications
    ADD CONSTRAINT organizer_applications_organizer_id_fkey FOREIGN KEY (organizer_id) REFERENCES public.organizers(id) ON DELETE CASCADE;


--
-- Name: organizer_members organizer_members_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizer_members
    ADD CONSTRAINT organizer_members_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: organizer_members organizer_members_organizer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizer_members
    ADD CONSTRAINT organizer_members_organizer_id_fkey FOREIGN KEY (organizer_id) REFERENCES public.organizers(id) ON DELETE CASCADE;


--
-- Name: platform_staff platform_staff_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_staff
    ADD CONSTRAINT platform_staff_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: sale_phase_categories sale_phase_categories_sale_phase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_phase_categories
    ADD CONSTRAINT sale_phase_categories_sale_phase_id_fkey FOREIGN KEY (sale_phase_id) REFERENCES public.sale_phases(id) ON DELETE CASCADE;


--
-- Name: sale_phase_categories sale_phase_categories_ticket_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_phase_categories
    ADD CONSTRAINT sale_phase_categories_ticket_category_id_fkey FOREIGN KEY (ticket_category_id) REFERENCES public.ticket_categories(id) ON DELETE CASCADE;


--
-- Name: sale_phases sale_phases_occurrence_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_phases
    ADD CONSTRAINT sale_phases_occurrence_id_fkey FOREIGN KEY (occurrence_id) REFERENCES public.occurrences(id) ON DELETE CASCADE;


--
-- Name: ticket_categories ticket_categories_occurrence_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_categories
    ADD CONSTRAINT ticket_categories_occurrence_id_fkey FOREIGN KEY (occurrence_id) REFERENCES public.occurrences(id) ON DELETE CASCADE;


--
-- Name: tickets tickets_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id);


--
-- Name: tickets tickets_occurrence_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_occurrence_id_fkey FOREIGN KEY (occurrence_id) REFERENCES public.occurrences(id);


--
-- Name: tickets tickets_order_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_order_item_id_fkey FOREIGN KEY (order_item_id) REFERENCES public.order_items(id);


--
-- Name: tickets tickets_ticket_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_ticket_category_id_fkey FOREIGN KEY (ticket_category_id) REFERENCES public.ticket_categories(id);


--
-- PostgreSQL database dump complete
--

\unrestrict dbmate


--
-- Dbmate schema migrations
--

INSERT INTO public.schema_migrations (version) VALUES
    ('20260725072013'),
    ('20260801065354'),
    ('20260801065443');
