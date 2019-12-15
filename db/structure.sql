SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: announcements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.announcements (
    id bigint NOT NULL,
    author bigint NOT NULL,
    original_author bigint NOT NULL,
    text character varying NOT NULL,
    valid_until timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: announcements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.announcements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: announcements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.announcements_id_seq OWNED BY public.announcements.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: forum_posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.forum_posts (
    id bigint NOT NULL,
    author bigint NOT NULL,
    original_author bigint NOT NULL,
    text character varying NOT NULL,
    mentions character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    hash_tags character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    forum_id bigint NOT NULL
);


--
-- Name: forum_posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.forum_posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: forum_posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.forum_posts_id_seq OWNED BY public.forum_posts.id;


--
-- Name: forums; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.forums (
    id bigint NOT NULL,
    subject character varying NOT NULL,
    last_post_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    sticky boolean DEFAULT false NOT NULL,
    locked boolean DEFAULT false NOT NULL
);


--
-- Name: forums_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.forums_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: forums_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.forums_id_seq OWNED BY public.forums.id;


--
-- Name: locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locations (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.locations_id_seq OWNED BY public.locations.id;


--
-- Name: photo_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.photo_metadata (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    content_type character varying NOT NULL,
    store_filename character varying NOT NULL,
    animated boolean DEFAULT false NOT NULL,
    md5_hash character varying NOT NULL,
    sizes jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    original_filename character varying NOT NULL
);


--
-- Name: photo_metadata_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.photo_metadata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: photo_metadata_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.photo_metadata_id_seq OWNED BY public.photo_metadata.id;


--
-- Name: post_photos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_photos (
    id bigint NOT NULL,
    stream_post_id bigint,
    photo_metadata_id bigint NOT NULL,
    forum_post_id bigint
);


--
-- Name: post_photos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.post_photos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: post_photos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.post_photos_id_seq OWNED BY public.post_photos.id;


--
-- Name: post_reactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_reactions (
    id bigint NOT NULL,
    stream_post_id bigint,
    reaction_id bigint NOT NULL,
    user_id bigint NOT NULL,
    forum_post_id bigint
);


--
-- Name: post_reactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.post_reactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: post_reactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.post_reactions_id_seq OWNED BY public.post_reactions.id;


--
-- Name: reactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reactions (
    id bigint NOT NULL,
    name character varying NOT NULL
);


--
-- Name: reactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reactions_id_seq OWNED BY public.reactions.id;


--
-- Name: registration_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.registration_codes (
    id bigint NOT NULL,
    code character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: registration_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.registration_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: registration_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.registration_codes_id_seq OWNED BY public.registration_codes.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sections (
    id bigint NOT NULL,
    name character varying,
    enabled boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sections_id_seq OWNED BY public.sections.id;


--
-- Name: stream_posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stream_posts (
    id bigint NOT NULL,
    author bigint NOT NULL,
    original_author bigint NOT NULL,
    text character varying NOT NULL,
    location_id bigint,
    locked boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    parent_chain bigint[] DEFAULT '{}'::bigint[],
    mentions character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    hash_tags character varying[] DEFAULT '{}'::character varying[] NOT NULL
);


--
-- Name: stream_posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stream_posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stream_posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stream_posts_id_seq OWNED BY public.stream_posts.id;


--
-- Name: user_forum_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_forum_views (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: user_forum_views_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_forum_views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_forum_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_forum_views_id_seq OWNED BY public.user_forum_views.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    username character varying,
    password character varying,
    role integer,
    status character varying,
    email character varying,
    display_name character varying,
    last_login timestamp without time zone,
    last_viewed_alerts timestamp without time zone,
    photo_hash character varying,
    last_photo_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    room_number character varying,
    real_name character varying,
    home_location character varying,
    current_location character varying,
    registration_code character varying,
    pronouns character varying,
    mute_reason character varying,
    ban_reason character varying,
    mute_thread character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: announcements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements ALTER COLUMN id SET DEFAULT nextval('public.announcements_id_seq'::regclass);


--
-- Name: forum_posts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forum_posts ALTER COLUMN id SET DEFAULT nextval('public.forum_posts_id_seq'::regclass);


--
-- Name: forums id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forums ALTER COLUMN id SET DEFAULT nextval('public.forums_id_seq'::regclass);


--
-- Name: locations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations ALTER COLUMN id SET DEFAULT nextval('public.locations_id_seq'::regclass);


--
-- Name: photo_metadata id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.photo_metadata ALTER COLUMN id SET DEFAULT nextval('public.photo_metadata_id_seq'::regclass);


--
-- Name: post_photos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_photos ALTER COLUMN id SET DEFAULT nextval('public.post_photos_id_seq'::regclass);


--
-- Name: post_reactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_reactions ALTER COLUMN id SET DEFAULT nextval('public.post_reactions_id_seq'::regclass);


--
-- Name: reactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reactions ALTER COLUMN id SET DEFAULT nextval('public.reactions_id_seq'::regclass);


--
-- Name: registration_codes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.registration_codes ALTER COLUMN id SET DEFAULT nextval('public.registration_codes_id_seq'::regclass);


--
-- Name: sections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sections ALTER COLUMN id SET DEFAULT nextval('public.sections_id_seq'::regclass);


--
-- Name: stream_posts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_posts ALTER COLUMN id SET DEFAULT nextval('public.stream_posts_id_seq'::regclass);


--
-- Name: user_forum_views id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_forum_views ALTER COLUMN id SET DEFAULT nextval('public.user_forum_views_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: announcements announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: forum_posts forum_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forum_posts
    ADD CONSTRAINT forum_posts_pkey PRIMARY KEY (id);


--
-- Name: forums forums_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forums
    ADD CONSTRAINT forums_pkey PRIMARY KEY (id);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);


--
-- Name: photo_metadata photo_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.photo_metadata
    ADD CONSTRAINT photo_metadata_pkey PRIMARY KEY (id);


--
-- Name: post_photos post_photos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_photos
    ADD CONSTRAINT post_photos_pkey PRIMARY KEY (id);


--
-- Name: post_reactions post_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_reactions
    ADD CONSTRAINT post_reactions_pkey PRIMARY KEY (id);


--
-- Name: reactions reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reactions
    ADD CONSTRAINT reactions_pkey PRIMARY KEY (id);


--
-- Name: registration_codes registration_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.registration_codes
    ADD CONSTRAINT registration_codes_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sections sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT sections_pkey PRIMARY KEY (id);


--
-- Name: stream_posts stream_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_posts
    ADD CONSTRAINT stream_posts_pkey PRIMARY KEY (id);


--
-- Name: user_forum_views user_forum_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_forum_views
    ADD CONSTRAINT user_forum_views_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_announcements_on_author; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_announcements_on_author ON public.announcements USING btree (author);


--
-- Name: index_forum_posts_on_author; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_forum_posts_on_author ON public.forum_posts USING btree (author);


--
-- Name: index_forum_posts_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_forum_posts_on_created_at ON public.forum_posts USING btree (created_at DESC);


--
-- Name: index_forum_posts_on_hash_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_forum_posts_on_hash_tags ON public.forum_posts USING gin (hash_tags);


--
-- Name: index_forum_posts_on_mentions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_forum_posts_on_mentions ON public.forum_posts USING gin (mentions);


--
-- Name: index_forum_posts_text; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_forum_posts_text ON public.forum_posts USING gin (to_tsvector('english'::regconfig, (text)::text));


--
-- Name: index_forums_on_sticky_and_last_post_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_forums_on_sticky_and_last_post_time ON public.forums USING btree (sticky DESC, last_post_time DESC);


--
-- Name: index_forums_subject; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_forums_subject ON public.forums USING gin (to_tsvector('english'::regconfig, (subject)::text));


--
-- Name: index_locations_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_locations_on_name ON public.locations USING btree (name);


--
-- Name: index_photo_metadata_on_md5_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_photo_metadata_on_md5_hash ON public.photo_metadata USING btree (md5_hash);


--
-- Name: index_photo_metadata_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_photo_metadata_on_user_id ON public.photo_metadata USING btree (user_id);


--
-- Name: index_post_photos_on_stream_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_photos_on_stream_post_id ON public.post_photos USING btree (stream_post_id);


--
-- Name: index_post_reactions_on_stream_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_reactions_on_stream_post_id ON public.post_reactions USING btree (stream_post_id);


--
-- Name: index_post_reactions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_reactions_on_user_id ON public.post_reactions USING btree (user_id);


--
-- Name: index_reactions_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reactions_on_name ON public.reactions USING btree (name);


--
-- Name: index_registration_codes_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_registration_codes_on_code ON public.registration_codes USING btree (code);


--
-- Name: index_sections_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sections_on_name ON public.sections USING btree (name);


--
-- Name: index_stream_posts_on_author; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stream_posts_on_author ON public.stream_posts USING btree (author);


--
-- Name: index_stream_posts_on_hash_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stream_posts_on_hash_tags ON public.stream_posts USING gin (hash_tags);


--
-- Name: index_stream_posts_on_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stream_posts_on_location_id ON public.stream_posts USING btree (location_id);


--
-- Name: index_stream_posts_on_mentions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stream_posts_on_mentions ON public.stream_posts USING gin (mentions);


--
-- Name: index_stream_posts_on_parent_chain; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stream_posts_on_parent_chain ON public.stream_posts USING gin (parent_chain);


--
-- Name: index_stream_posts_text; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stream_posts_text ON public.stream_posts USING gin (to_tsvector('english'::regconfig, (text)::text));


--
-- Name: index_user_forum_views_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_forum_views_on_user_id ON public.user_forum_views USING btree (user_id);


--
-- Name: index_users_on_display_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_display_name ON public.users USING btree (display_name);


--
-- Name: index_users_on_registration_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_registration_code ON public.users USING btree (registration_code);


--
-- Name: index_users_on_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_username ON public.users USING btree (username);


--
-- Name: post_photos fk_rails_0af974c734; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_photos
    ADD CONSTRAINT fk_rails_0af974c734 FOREIGN KEY (forum_post_id) REFERENCES public.forum_posts(id) ON DELETE CASCADE;


--
-- Name: post_reactions fk_rails_1b6a1beaa9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_reactions
    ADD CONSTRAINT fk_rails_1b6a1beaa9 FOREIGN KEY (forum_post_id) REFERENCES public.forum_posts(id) ON DELETE CASCADE;


--
-- Name: post_reactions fk_rails_1da76e258b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_reactions
    ADD CONSTRAINT fk_rails_1da76e258b FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: announcements fk_rails_2eb97675c2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT fk_rails_2eb97675c2 FOREIGN KEY (author) REFERENCES public.users(id);


--
-- Name: user_forum_views fk_rails_3a04857500; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_forum_views
    ADD CONSTRAINT fk_rails_3a04857500 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: forum_posts fk_rails_3ddde06812; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forum_posts
    ADD CONSTRAINT fk_rails_3ddde06812 FOREIGN KEY (original_author) REFERENCES public.users(id);


--
-- Name: forum_posts fk_rails_61f00b1427; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forum_posts
    ADD CONSTRAINT fk_rails_61f00b1427 FOREIGN KEY (forum_id) REFERENCES public.forums(id) ON DELETE CASCADE;


--
-- Name: post_photos fk_rails_75b2cf5242; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_photos
    ADD CONSTRAINT fk_rails_75b2cf5242 FOREIGN KEY (photo_metadata_id) REFERENCES public.photo_metadata(id) ON DELETE CASCADE;


--
-- Name: stream_posts fk_rails_7ae28b8d9b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_posts
    ADD CONSTRAINT fk_rails_7ae28b8d9b FOREIGN KEY (location_id) REFERENCES public.locations(id) ON DELETE SET NULL;


--
-- Name: post_reactions fk_rails_7c0785fdf4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_reactions
    ADD CONSTRAINT fk_rails_7c0785fdf4 FOREIGN KEY (reaction_id) REFERENCES public.reactions(id) ON DELETE CASCADE;


--
-- Name: stream_posts fk_rails_83c30e49f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_posts
    ADD CONSTRAINT fk_rails_83c30e49f6 FOREIGN KEY (original_author) REFERENCES public.users(id);


--
-- Name: post_photos fk_rails_8978c3e2f7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_photos
    ADD CONSTRAINT fk_rails_8978c3e2f7 FOREIGN KEY (stream_post_id) REFERENCES public.stream_posts(id) ON DELETE CASCADE;


--
-- Name: forum_posts fk_rails_95160ebc33; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forum_posts
    ADD CONSTRAINT fk_rails_95160ebc33 FOREIGN KEY (author) REFERENCES public.users(id);


--
-- Name: post_reactions fk_rails_af77dda289; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_reactions
    ADD CONSTRAINT fk_rails_af77dda289 FOREIGN KEY (stream_post_id) REFERENCES public.stream_posts(id) ON DELETE CASCADE;


--
-- Name: photo_metadata fk_rails_b5497d241a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.photo_metadata
    ADD CONSTRAINT fk_rails_b5497d241a FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: announcements fk_rails_bd87d26586; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT fk_rails_bd87d26586 FOREIGN KEY (original_author) REFERENCES public.users(id);


--
-- Name: stream_posts fk_rails_eb175487ec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_posts
    ADD CONSTRAINT fk_rails_eb175487ec FOREIGN KEY (author) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20190531182420'),
('20190531185609'),
('20190531190150'),
('20190531192028'),
('20190827212516'),
('20190904025735'),
('20190904041441'),
('20190926170652'),
('20190926183324'),
('20191003040901'),
('20191010023114'),
('20191124032402'),
('20191124040002'),
('20191209011020'),
('20191209043219');


