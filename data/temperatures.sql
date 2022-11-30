CREATE TABLE public.temperatures
(
    id serial NOT NULL,
    date date NOT NULL,
    temperature numeric NOT NULL,
    city character varying(255) NOT NULL,
    country character varying(255) NOT NULL,
    PRIMARY KEY (id)
);

ALTER TABLE IF EXISTS public.temperatures
    OWNER to training;