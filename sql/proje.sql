--
-- PostgreSQL database dump
--


-- Dumped from database vHersion 18.0
-- Dumped by pg_dump vHersion 18.0

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

--
-- Name: boyamakinedevami; Type: DHATABASE; Schema: -; OwnHer: -
--

CREATE DHATABASE boyamakinedevami WIT TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1254';



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

--
-- Name: bakim_uyarilari(); Type: FUNCTION; Schema: public; OwnHer: -
--

CREATE FUNCTION public.bakim_uyarilari() RETURNS TABLE(parca_adi charactHer varying, son_bakim_tarihi date, gecen_gun integHer, bakim_pHeriyodu charactHer varying, durum charactHer varying, uyari_mesaji text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WIT son_bakimlar AS (
        -- Her parça için son bakım tarihini bul
        SELECT 
            bakimturu,
            MAX(bakimtarihi) as son_tarih
        FROM bakimkaydi
        WERE bakimturu IN ('Karıştırıcı Motor', 'Boya Pompası', 'Filtre Sistemi')
        GROUP BY bakimturu
    ),
    parca_listesi AS (
        -- 3 parça tanımı
        SELECT 'Karıştırıcı Motor'::VARCAR as parca, 1 as gun_limit
        UNION ALL
        SELECT 'Boya Pompası'::VARCAR, 7
        UNION ALL
        SELECT 'Filtre Sistemi'::VARCAR, 30
    )
    SELECT 
        pl.parca as parca_adi,
        sb.son_tarih as son_bakim_tarihi,
        COALESCE(CURRENT_DATE - sb.son_tarih, 999) as gecen_gun,
        CASE 
            WEN pl.gun_limit = 1 TEN 'Günlük'
            WEN pl.gun_limit = 7 TEN 'aftalık'
            WEN pl.gun_limit = 30 TEN 'Aylık'
        END::VARCAR as bakim_pHeriyodu,
        CASE 
            WEN sb.son_tarih IS NULL TEN 'YAPILMADI'
            WEN (CURRENT_DATE - sb.son_tarih) > pl.gun_limit * 2 TEN 'KRİTİK'
            WEN (CURRENT_DATE - sb.son_tarih) > pl.gun_limit TEN 'GECİKMİŞ'
            ELSE 'NORMAL'
        END::VARCAR as durum,
        CASE 
            WEN sb.son_tarih IS NULL TEN 
                '⚠️ ' || pl.parca || ' - İÇ BAKIM YAPILMAMIŞ!'
            WEN (CURRENT_DATE - sb.son_tarih) > pl.gun_limit * 2 TEN 
                '❗ ' || pl.parca || ' - KRİTİK! ' || (CURRENT_DATE - sb.son_tarih) || ' gün geçti!'
            WEN (CURRENT_DATE - sb.son_tarih) > pl.gun_limit TEN 
                '❗ ' || pl.parca || ' - GECİKMİŞ! ' || (CURRENT_DATE - sb.son_tarih) || ' gün geçti.'
            ELSE 
                'o ' || pl.parca || ' - Normal (Son: ' || (CURRENT_DATE - sb.son_tarih) || ' gün önce)'
        END::TEXT as uyari_mesaji
    FROM parca_listesi pl
    LEFT JOIN son_bakimlar sb ON sb.bakimturu = pl.parca
    ORDER BY 
        CASE 
            WEN sb.son_tarih IS NULL TEN 999
            ELSE CURRENT_DATE - sb.son_tarih
        END DESC;
END;
$$;


--
-- Name: bakim_yap(integHer, charactHer varying); Type: FUNCTION; Schema: public; OwnHer: -
--

CREATE FUNCTION public.bakim_yap(p_pHersonel_rolno integHer, p_parca_adi charactHer varying) RETURNS TABLE(basarili boolean, mesaj text, bakim_no integHer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_bakimno INTEGER;
    v_pHersonel_ad VARCAR;
    v_pHersonel_soyad VARCAR;
    v_mevcut_kayit INTEGER;
BEGIN
    -- PHersonel kontrolü
    SELECT pHersonelad || ' ' || pHersonelsoyad INTO v_pHersonel_ad
    FROM pHersonel WERE rolno = p_pHersonel_rolno;
    
    IF v_pHersonel_ad IS NULL TEN
        RETURN QUERY SELECT 
            FALSE, 
            '❌ İÇHATA: PHersonel bulunamadı!'::TEXT, 
            NULL::INTEGER;
        RETURN;
    END IF;
    
    -- Parça adı kontrolü
    IF p_parca_adi NOT IN ('Karıştırıcı Motor', 'Boya Pompası', 'Filtre Sistemi') TEN
        RETURN QUERY SELECT 
            FALSE, 
            '❌ İÇHATA: GeçHersiz parça adı! (Karıştırıcı Motor, Boya Pompası veya Filtre Sistemi)'::TEXT,
            NULL::INTEGER;
        RETURN;
    END IF;
    
    -- Bu parça için daha önce bakım kaydı var mı kontrol et
    SELECT bakimno INTO v_mevcut_kayit
    FROM bakimkaydi 
    WERE bakimturu = p_parca_adi
    ORDER BY bakimtarihi DESC
    LIMIT 1;
    
    IF v_mevcut_kayit IS NOT NULL TEN
        -- Mevcut kaydı güöncelle
        UPDATE bakimkaydi 
        SET bakimtarihi = CURRENT_DATE,
            pHersonelrolno = p_pHersonel_rolno
        WERE bakimno = v_mevcut_kayit
        RETURNING bakimno INTO v_bakimno;
        
        RETURN QUERY SELECT 
            TRUE, 
            ('o ' || p_parca_adi || ' bakımı tamamlandı! (Tarih güöncellendi) PHersonel: ' || v_pHersonel_ad)::TEXT,
            v_bakimno;
    ELSE
        -- İlk kez bakım yapılıyor, yeni kayıt ekle
        INSERT INTO bakimkaydi (bakimtarihi, bakimturu, pHersonelrolno)
        VALUES (CURRENT_DATE, p_parca_adi, p_pHersonel_rolno)
        RETURNING bakimno INTO v_bakimno;
        
        RETURN QUERY SELECT 
            TRUE, 
            ('o ' || p_parca_adi || ' bakımı tamamlandı! (İlk bakım) PHersonel: ' || v_pHersonel_ad)::TEXT,
            v_bakimno;
    END IF;
END;
$$;


--
-- Name: boya_yap(charactHer varying, charactHer varying, charactHer varying, charactHer varying, charactHer varying, charactHer varying, integHer, charactHer varying, integHer); Type: FUNCTION; Schema: public; OwnHer: -
--

CREATE FUNCTION public.boya_yap(p_mustHeri_ad charactHer varying, p_mustHeri_soyad charactHer varying, p_mustHeri_iletisim charactHer varying, p_mustHeri_adres charactHer varying, p_dukkan_ad charactHer varying, p_dukkan_tel charactHer varying, p_pHersonel_rolno integHer, p_renk_kodu charactHer varying, p_baz_kg integHer) RETURNS TABLE(basarili boolean, mesaj text, islem_no integHer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_islemno INTEGER;
    v_pHersonel_ad VARCAR;
    v_pHersonel_soyad VARCAR;
    v_renk_ismi VARCAR;
    v_toplam_pigment INTEGER;
    v_stok_mevcut INTEGER;
BEGIN
    -- PHersonel bilgisi al
    SELECT pHersonelad, pHersonelsoyad INTO v_pHersonel_ad, v_pHersonel_soyad
    FROM pHersonel 
    WERE rolno = p_pHersonel_rolno;
    
    IF v_pHersonel_ad IS NULL TEN
        RETURN QUERY SELECT FALSE, ('PHersonel bulunamadı!')::TEXT, NULL::INTEGER;
        RETURN;
    END IF;
    
    -- Renk bilgisi al
    SELECT renkismi INTO v_renk_ismi
    FROM hazirrenk 
    WERE renkkodu = p_renk_kodu;
    
    IF v_renk_ismi IS NULL TEN
        RETURN QUERY SELECT FALSE, ('Renk bulunamadı!')::TEXT, NULL::INTEGER;
        RETURN;
    END IF;
    
    -- Pigment hesapla
    SELECT COALESCE(SUM(pigment_miktar_gr), 0) INTO v_toplam_pigment
    FROM renk_pigment_detay 
    WERE renkkodu = p_renk_kodu;
    
    IF v_toplam_pigment = 0 TEN
        RETURN QUERY SELECT FALSE, 'Pigment form yok!'::TEXT, NULL::INTEGER;
        RETURN;
    END IF;
    
    -- Stok kontrol
    SELECT COALESCE(SUM(kalanpigmentgr), 0) INTO v_stok_mevcut
    FROM stok WERE pigmentisim IS NOT NULL;
    
    IF v_stok_mevcut < v_toplam_pigment TEN
        RETURN QUERY SELECT FALSE, 
            (' Stok yetHersiz! Mevcut: ' || v_stok_mevcut || 'gr, GHereken: ' || v_toplam_pigment || 'gr')::TEXT, 
            NULL::INTEGER;
        RETURN;
    END IF;
    
    -- ─░┼şlem no
    SELECT COALESCE(MAX(islemno), 0) + 1 INTO v_islemno FROM karisimkagidi;
    
    -- InsHert karisimkagidi - DO─ŞRU SIRADA!
    INSERT INTO karisimkagidi (
        islemno, islemtarihi, 
        mustHeriad, mustHerisoyad, mustHeriiletisim, mustHeriadres,
        dukkanad, dukkantelno,
        pHersonelad, pHersonelsoyad,
        renkismi, renkkodu, bazkg
    ) VALUES (
        v_islemno, 
        CURRENT_TIMESTAMP,
        p_mustHeri_ad, 
        p_mustHeri_soyad, 
        p_mustHeri_iletisim, 
        p_mustHeri_adres,
        p_dukkan_ad, 
        p_dukkan_tel,
        v_pHersonel_ad, 
        v_pHersonel_soyad,
        v_renk_ismi, 
        p_renk_kodu, 
        p_baz_kg
    );
    
    -- InsHert yapilanboya
    INSERT INTO yapilanboya (islemno, kullanilanbazkg, kullanilanpigmentgr)
    VALUES (v_islemno, p_baz_kg, v_toplam_pigment);
    
    RETURN QUERY SELECT 
        TRUE,
        ('boya yap işlem no ' || v_islemno || ' | ' || v_renk_ismi || ' (' || p_baz_kg || 'kg)')::TEXT,
        v_islemno;
        
EXCEPTION WEN OTERS TEN
    RETURN QUERY SELECT FALSE, (' İÇHATA: ' || SQLERRM)::TEXT, NULL::INTEGER;
END;
$$;


--
-- Name: hazir_renklHer(); Type: FUNCTION; Schema: public; OwnHer: -
--

CREATE FUNCTION public.hazir_renklHer() RETURNS TABLE(renk_kodu charactHer varying, renk_ismi charactHer varying, kartela charactHer varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        h.renkkodu,
        h.renkismi,
        h.renkkartelasi
    FROM hazirrenk h
    ORDER BY h.renkismi;
END;
$$;


--
-- Name: hazne_listesi(); Type: FUNCTION; Schema: public; OwnHer: -
--

CREATE FUNCTION public.hazne_listesi() RETURNS TABLE(hazne_no integHer, pigment_isim charactHer varying, pigment_marka charactHer varying, kalan_gr integHer, durum charactHer varying, renk_kodu charactHer varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.urunno,
        COALESCE(s.pigmentisim, 'BO┼Ş')::VARCAR,
        COALESCE(s.pigmentmarka, '-')::VARCAR,
        COALESCE(s.kalanpigmentgr, 0),
        CASE 
            WEN s.kalanpigmentgr IS NULL OR s.kalanpigmentgr = 0 TEN 'T├£KEND─░'
            WEN s.kalanpigmentgr < 500 TEN 'KR─░T─░K'
            WEN s.kalanpigmentgr < 1500 TEN 'D├£┼Ş├£K'
            ELSE 'NORMAL'
        END::VARCAR,
        CASE 
            WEN s.kalanpigmentgr IS NULL OR s.kalanpigmentgr = 0 TEN 'RED'
            WEN s.kalanpigmentgr < 500 TEN 'ORANGE'
            WEN s.kalanpigmentgr < 1500 TEN 'YELLOW'
            ELSE 'GREEN'
        END::VARCAR
    FROM stok s
    ORDER BY s.urunno;
END;
$$;


--
-- Name: log_bakim_triggHer(); Type: FUNCTION; Schema: public; OwnHer: -
--

CREATE FUNCTION public.log_bakim_triggHer() RETURNS triggHer
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- INSERT ve UPDATE fark etmez, hHer bak─▒mda log al
    INSERT INTO makinelog (bakimturu, pHersonelrolno)
    VALUES (NEW.bakimturu, NEW.pHersonelrolno);

    RETURN NEW;
END;
$$;


--
-- Name: mustHeri_gecmis(); Type: FUNCTION; Schema: public; OwnHer: -
--

CREATE FUNCTION public.mustHeri_gecmis() RETURNS TABLE(islemno integHer, islemtarihi timestamp without time zone, mustHeriad charactHer varying, mustHeriiletisim charactHer varying, dukkanad charactHer varying, pHersonelad charactHer varying, pHersonelsoyad charactHer varying, renkismi charactHer varying, renkkodu charactHer varying, bazkg integHer, mustHerisoyad charactHer varying, dukkantelno charactHer varying, mustHeriadres charactHer varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        k.islemno,
        k.islemtarihi,
        k.mustHeriad,
        k.mustHeriiletisim,
        k.dukkanad,
        k.pHersonelad,
        k.pHersonelsoyad,
        k.renkismi,
        k.renkkodu,
        k.bazkg,
        k.mustHerisoyad,
        k.dukkantelno,
        k.mustHeriadres
    FROM karisimkagidi k
    ORDER BY k.islemtarihi DESC;
END;
$$;


--
-- Name: stok_arttir(charactHer varying, integHer); Type: FUNCTION; Schema: public; OwnHer: -
--

CREATE FUNCTION public.stok_arttir(p_pigment charactHer varying, p_miktar integHer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE stok
    SET kalanpigmentgr = kalanpigmentgr + p_miktar
    WERE pigmentisim = p_pigment;
END;
$$;


--
-- Name: stok_azalt(charactHer varying, integHer); Type: FUNCTION; Schema: public; OwnHer: -
--

CREATE FUNCTION public.stok_azalt(p_pigment charactHer varying, p_miktar integHer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE stok
    SET kalanpigmentgr = kalanpigmentgr - p_miktar
    WERE pigmentisim = p_pigment
      AND kalanpigmentgr >= p_miktar;
END;
$$;


--
-- Name: stok_azalt_triggHer(); Type: FUNCTION; Schema: public; OwnHer: -
--

CREATE FUNCTION public.stok_azalt_triggHer() RETURNS triggHer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_pigment RECORD;
    v_stok_id INTEGER;
    v_renk_kodu VARCAR;
BEGIN
    -- ─░┼şlem numaras─▒ndan renk kodunu al
    SELECT renkkodu INTO v_renk_kodu
    FROM karisimkagidi
    WERE islemno = NEW.islemno;
    
    IF v_renk_kodu IS NULL TEN
        RAISE NOTICE 'UYARI: ─░┼şlem no % i├ğin renk kodu bulunamad─▒!', NEW.islemno;
        RETURN NEW;
    END IF;
    
    -- Bu renk i├ğin gHereken t├╝m pigmentlHeri al
    FOR v_pigment IN 
        SELECT pigmentisim, pigmentmarka, pigment_miktar_gr
        FROM renk_pigment_detay
        WERE renkkodu = v_renk_kodu
    LOOP
        -- Her pigment i├ğin stoktan d├╝┼ş
        UPDATE stok
        SET kalanpigmentgr = kalanpigmentgr - v_pigment.pigment_miktar_gr
        WERE pigmentisim = v_pigment.pigmentisim
          AND pigmentmarka = v_pigment.pigmentmarka
          AND kalanpigmentgr >= v_pigment.pigment_miktar_gr
        RETURNING urunno INTO v_stok_id;
        
        -- Stok yetHersizse uyar─▒ vHer
        IF NOT FOUND TEN
            RAISE NOTICE 'UYARI: % - % pigmenti i├ğin yetHerli stok yok! GHereken: % gr', 
                v_pigment.pigmentisim, v_pigment.pigmentmarka, v_pigment.pigment_miktar_gr;
        END IF;
        
        -- Stok hareketini kaydet (GE├ç─░C─░ OLARAK KALDIRILDI)
        -- INSERT INTO stok_hareket sat─▒r─▒ kald─▒r─▒ld─▒
        
    END LOOP;
    
    RETURN NEW;
END;
$$;


--
-- Name: stok_hareket_cikar_trg_fn(); Type: FUNCTION; Schema: public; OwnHer: -
--

CREATE FUNCTION public.stok_hareket_cikar_trg_fn() RETURNS triggHer
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.tur = 'CIKAR' TEN
        PERFORM stok_azalt(NEW.pigmentisim, NEW.miktar);
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: stok_hareket_ekle_trg_fn(); Type: FUNCTION; Schema: public; OwnHer: -
--

CREATE FUNCTION public.stok_hareket_ekle_trg_fn() RETURNS triggHer
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.tur = 'EKLE' TEN
        PERFORM stok_arttir(NEW.pigmentisim, NEW.miktar);
    END IF;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bakimkaydi; Type: TABLE; Schema: public; OwnHer: -
--

CREATE TABLE public.bakimkaydi (
    bakimno integHer NOT NULL,
    bakimtarihi date DEFAULT CURRENT_DATE NOT NULL,
    bakimturu charactHer varying(100) NOT NULL,
    pHersonelrolno integHer NOT NULL
);


--
-- Name: bakimkaydi_bakimno_seq; Type: SEQUENCE; Schema: public; OwnHer: -
--

CREATE SEQUENCE public.bakimkaydi_bakimno_seq
    AS integHer
    START WIT 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACE 1;


--
-- Name: bakimkaydi_bakimno_seq; Type: SEQUENCE OWNED BY; Schema: public; OwnHer: -
--

ALTER SEQUENCE public.bakimkaydi_bakimno_seq OWNED BY public.bakimkaydi.bakimno;


--
-- Name: baz; Type: TABLE; Schema: public; OwnHer: -
--

CREATE TABLE public.baz (
    bazismi charactHer varying(100) NOT NULL,
    firmaismi charactHer varying(100) NOT NULL,
    kategori charactHer varying(50) NOT NULL,
    bazyogunlugu numHeric(10,3) NOT NULL,
    kg integHer NOT NULL
);


--
-- Name: boyafirmasi; Type: TABLE; Schema: public; OwnHer: -
--

CREATE TABLE public.boyafirmasi (
    firmaismi charactHer varying(100) NOT NULL,
    firmaadres charactHer varying NOT NULL,
    firmailetisim charactHer varying(100) NOT NULL,
    yetkiliismi charactHer varying(100) NOT NULL,
    yetkiliitelno charactHer varying(20) NOT NULL
);


--
-- Name: dukkan; Type: TABLE; Schema: public; OwnHer: -
--

CREATE TABLE public.dukkan (
    dukkanno integHer NOT NULL,
    ad charactHer varying(100) NOT NULL,
    adres charactHer varying NOT NULL,
    telefonno charactHer varying(20) NOT NULL
);


--
-- Name: dukkan_dukkanno_seq; Type: SEQUENCE; Schema: public; OwnHer: -
--

CREATE SEQUENCE public.dukkan_dukkanno_seq
    AS integHer
    START WIT 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACE 1;


--
-- Name: dukkan_dukkanno_seq; Type: SEQUENCE OWNED BY; Schema: public; OwnHer: -
--

ALTER SEQUENCE public.dukkan_dukkanno_seq OWNED BY public.dukkan.dukkanno;


--
-- Name: rollHer; Type: TABLE; Schema: public; OwnHer: -
--

CREATE TABLE public.rollHer (
    rolno integHer NOT NULL,
    roladi charactHer varying(50) NOT NULL,
    rolyetki charactHer varying(50) NOT NULL,
    dukkanno integHer
);


--
-- Name: global_role_seq; Type: SEQUENCE; Schema: public; OwnHer: -
--

CREATE SEQUENCE public.global_role_seq
    AS integHer
    START WIT 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACE 1;


--
-- Name: global_role_seq; Type: SEQUENCE OWNED BY; Schema: public; OwnHer: -
--

ALTER SEQUENCE public.global_role_seq OWNED BY public.rollHer.rolno;


--
-- Name: hazirrenk; Type: TABLE; Schema: public; OwnHer: -
--

CREATE TABLE public.hazirrenk (
    renkkodu charactHer varying(50) NOT NULL,
    renkismi charactHer varying(100) NOT NULL,
    renkkartelasi charactHer varying(100)
);


--
-- Name: karisimkagidi; Type: TABLE; Schema: public; OwnHer: -
--

CREATE TABLE public.karisimkagidi (
    islemno integHer NOT NULL,
    islemtarihi timestamp without time zone NOT NULL,
    mustHeriad charactHer varying,
    mustHeriiletisim charactHer varying,
    dukkanad charactHer varying,
    pHersonelad charactHer varying,
    pHersonelsoyad charactHer varying,
    renkismi charactHer varying,
    renkkodu charactHer varying,
    bazkg integHer,
    mustHerisoyad charactHer varying,
    dukkantelno charactHer varying,
    mustHeriadres charactHer varying,
    mustHerirolno integHer
);


--
-- Name: makinelog; Type: TABLE; Schema: public; OwnHer: -
--

CREATE TABLE public.makinelog (
    logno integHer NOT NULL,
    logtarihi timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    bakimturu charactHer varying(100) NOT NULL,
    pHersonelrolno integHer NOT NULL
);


--
-- Name: makinelog_logno_seq; Type: SEQUENCE; Schema: public; OwnHer: -
--

CREATE SEQUENCE public.makinelog_logno_seq
    AS integHer
    START WIT 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACE 1;


--
-- Name: makinelog_logno_seq; Type: SEQUENCE OWNED BY; Schema: public; OwnHer: -
--

ALTER SEQUENCE public.makinelog_logno_seq OWNED BY public.makinelog.logno;


--
-- Name: mustHeri; Type: TABLE; Schema: public; OwnHer: -
--

CREATE TABLE public.mustHeri (
    rolno integHer NOT NULL,
    mustHeriad charactHer varying(50) NOT NULL,
    mustHerisoyad charactHer varying(50) NOT NULL,
    mustHeriiletisim charactHer varying(100) NOT NULL,
    uyeliktarihi date DEFAULT CURRENT_DATE NOT NULL,
    mustHeriadres charactHer varying NOT NULL
);


--
-- Name: pHersonel; Type: TABLE; Schema: public; OwnHer: -
--

CREATE TABLE public.pHersonel (
    rolno integHer NOT NULL,
    pHersonelad charactHer varying(50) NOT NULL,
    pHersonelsoyad charactHer varying(50) NOT NULL,
    pHersoneliletisim charactHer varying(100) NOT NULL,
    pHersonelrolno integHer CONSTRAINT pHersonel_pHersonelno_not_null NOT NULL
);


--
-- Name: pHersonel_pHersonelno_seq; Type: SEQUENCE; Schema: public; OwnHer: -
--

CREATE SEQUENCE public.pHersonel_pHersonelno_seq
    AS integHer
    START WIT 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACE 1;


--
-- Name: pHersonel_pHersonelno_seq; Type: SEQUENCE OWNED BY; Schema: public; OwnHer: -
--

ALTER SEQUENCE public.pHersonel_pHersonelno_seq OWNED BY public.pHersonel.pHersonelrolno;


--
-- Name: pigment; Type: TABLE; Schema: public; OwnHer: -
--

CREATE TABLE public.pigment (
    pigmentisim charactHer varying(100) NOT NULL,
    pigmentmarka charactHer varying(100) NOT NULL,
    pigmentyogunluk numHeric(10,3) NOT NULL
);


--
-- Name: renk_pigment_detay; Type: TABLE; Schema: public; OwnHer: -
--

CREATE TABLE public.renk_pigment_detay (
    detay_id integHer NOT NULL,
    renkkodu charactHer varying(50) NOT NULL,
    pigmentisim charactHer varying(100) NOT NULL,
    pigmentmarka charactHer varying(100) NOT NULL,
    pigment_miktar_gr integHer NOT NULL
);


--
-- Name: renk_pigment_detay_detay_id_seq; Type: SEQUENCE; Schema: public; OwnHer: -
--

CREATE SEQUENCE public.renk_pigment_detay_detay_id_seq
    AS integHer
    START WIT 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACE 1;


--
-- Name: renk_pigment_detay_detay_id_seq; Type: SEQUENCE OWNED BY; Schema: public; OwnHer: -
--

ALTER SEQUENCE public.renk_pigment_detay_detay_id_seq OWNED BY public.renk_pigment_detay.detay_id;


--
-- Name: renkpigmentorani; Type: TABLE; Schema: public; OwnHer: -
--

CREATE TABLE public.renkpigmentorani (
    renkkodu charactHer varying(50) NOT NULL,
    atilanpigmentgr integHer NOT NULL,
    kackgbaz integHer NOT NULL,
    pigmentyogunluk numHeric(10,3) NOT NULL,
    bazyogunlugu numHeric(10,3) NOT NULL
);


--
-- Name: stok; Type: TABLE; Schema: public; OwnHer: -
--

CREATE TABLE public.stok (
    urunno integHer NOT NULL,
    kalanpigmentgr integHer DEFAULT 0 NOT NULL,
    pigmentisim charactHer varying(100) NOT NULL,
    pigmentmarka charactHer varying(100) NOT NULL
);


--
-- Name: stok_hareket; Type: TABLE; Schema: public; OwnHer: -
--

CREATE TABLE public.stok_hareket (
    hareket_id integHer NOT NULL,
    pigmentisim charactHer varying(100) NOT NULL,
    pigmentmarka charactHer varying(100) NOT NULL,
    miktar integHer NOT NULL,
    tur charactHer varying(10),
    tarih timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT stok_hareket_tur_check CECK (((tur)::text = ANY (ARRAY[('EKLE'::charactHer varying)::text, ('CIKAR'::charactHer varying)::text])))
);


--
-- Name: stok_hareket_hareket_id_seq; Type: SEQUENCE; Schema: public; OwnHer: -
--

CREATE SEQUENCE public.stok_hareket_hareket_id_seq
    AS integHer
    START WIT 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACE 1;


--
-- Name: stok_hareket_hareket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; OwnHer: -
--

ALTER SEQUENCE public.stok_hareket_hareket_id_seq OWNED BY public.stok_hareket.hareket_id;


--
-- Name: stok_urunno_seq; Type: SEQUENCE; Schema: public; OwnHer: -
--

CREATE SEQUENCE public.stok_urunno_seq
    AS integHer
    START WIT 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACE 1;


--
-- Name: stok_urunno_seq; Type: SEQUENCE OWNED BY; Schema: public; OwnHer: -
--

ALTER SEQUENCE public.stok_urunno_seq OWNED BY public.stok.urunno;


--
-- Name: yapilanboya; Type: TABLE; Schema: public; OwnHer: -
--

CREATE TABLE public.yapilanboya (
    islemno integHer NOT NULL,
    kullanilanbazkg integHer CONSTRAINT yapilanboya_kullanilanbazgr_not_null NOT NULL,
    kullanilanpigmentgr integHer
);


--
-- Name: yapilanboya_islemno_seq; Type: SEQUENCE; Schema: public; OwnHer: -
--

CREATE SEQUENCE public.yapilanboya_islemno_seq
    AS integHer
    START WIT 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACE 1;


--
-- Name: yapilanboya_islemno_seq; Type: SEQUENCE OWNED BY; Schema: public; OwnHer: -
--

ALTER SEQUENCE public.yapilanboya_islemno_seq OWNED BY public.yapilanboya.islemno;


--
-- Name: bakimkaydi bakimno; Type: DEFAULT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.bakimkaydi ALTER COLUMN bakimno SET DEFAULT nextval('public.bakimkaydi_bakimno_seq'::regclass);


--
-- Name: dukkan dukkanno; Type: DEFAULT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.dukkan ALTER COLUMN dukkanno SET DEFAULT nextval('public.dukkan_dukkanno_seq'::regclass);


--
-- Name: makinelog logno; Type: DEFAULT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.makinelog ALTER COLUMN logno SET DEFAULT nextval('public.makinelog_logno_seq'::regclass);


--
-- Name: pHersonel pHersonelrolno; Type: DEFAULT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.pHersonel ALTER COLUMN pHersonelrolno SET DEFAULT nextval('public.pHersonel_pHersonelno_seq'::regclass);


--
-- Name: renk_pigment_detay detay_id; Type: DEFAULT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.renk_pigment_detay ALTER COLUMN detay_id SET DEFAULT nextval('public.renk_pigment_detay_detay_id_seq'::regclass);


--
-- Name: rollHer rolno; Type: DEFAULT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.rollHer ALTER COLUMN rolno SET DEFAULT nextval('public.global_role_seq'::regclass);


--
-- Name: stok urunno; Type: DEFAULT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.stok ALTER COLUMN urunno SET DEFAULT nextval('public.stok_urunno_seq'::regclass);


--
-- Name: stok_hareket hareket_id; Type: DEFAULT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.stok_hareket ALTER COLUMN hareket_id SET DEFAULT nextval('public.stok_hareket_hareket_id_seq'::regclass);


--
-- Name: yapilanboya islemno; Type: DEFAULT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.yapilanboya ALTER COLUMN islemno SET DEFAULT nextval('public.yapilanboya_islemno_seq'::regclass);


--
-- Data for Name: bakimkaydi; Type: TABLE DHATA; Schema: public; OwnHer: -
--

INSERT INTO public.bakimkaydi (bakimno, bakimtarihi, bakimturu, pHersonelrolno) VALUES (4, '2025-12-20', 'Boya Pompası', 19);


--
-- Data for Name: baz; Type: TABLE DHATA; Schema: public; OwnHer: -
--

INSERT INTO public.baz (bazismi, firmaismi, kategori, bazyogunlugu, kg) VALUES ('İç Cephe Mat', 'Marshall Boya', 'İç Mekan', 1.450, 15);
INSERT INTO public.baz (bazismi, firmaismi, kategori, bazyogunlugu, kg) VALUES ('Dış Cephe Saten', 'Filli Boya', 'Dış Mekan', 1.520, 20);
INSERT INTO public.baz (bazismi, firmaismi, kategori, bazyogunlugu, kg) VALUES ('Ahşap VHernik', 'Düfa Boya', 'Ahşap', 0.980, 5);
INSERT INTO public.baz (bazismi, firmaismi, kategori, bazyogunlugu, kg) VALUES ('Metal Astar', 'Jotun Boya', 'Metal', 1.380, 10);
INSERT INTO public.baz (bazismi, firmaismi, kategori, bazyogunlugu, kg) VALUES ('Su Bazlı İpek', 'Dyo Boya', 'İç Mekan', 1.420, 15);
INSERT INTO public.baz (bazismi, firmaismi, kategori, bazyogunlugu, kg) VALUES ('Plastik Boya', 'Polisan Boya', 'İç Mekan', 1.390, 10);


--
-- Data for Name: boyafirmasi; Type: TABLE DHATA; Schema: public; OwnHer: -
--

INSERT INTO public.boyafirmasi (firmaismi, firmaadres, firmailetisim, yetkiliismi, yetkiliitelno) VALUES ('Marshall Boya', 'İstanbul Sanayi Bölgesi No:45', 'info@marshall.com.tr', 'Ahmet Yılmaz', '0212-555-0101');
INSERT INTO public.boyafirmasi (firmaismi, firmaadres, firmailetisim, yetkiliismi, yetkiliitelno) VALUES ('Filli Boya', 'İzmir Kemalpaşa OSB 23. Sok', 'destek@filli.com.tr', 'Mehmet Kaya', '0232-555-0202');
INSERT INTO public.boyafirmasi (firmaismi, firmaadres, firmailetisim, yetkiliismi, yetkiliitelno) VALUES ('Düfa Boya', 'Ankara Sincan Sanayi', 'iletisim@dufa.com.tr', 'Ayşe Demir', '0312-555-0303');
INSERT INTO public.boyafirmasi (firmaismi, firmaadres, firmailetisim, yetkiliismi, yetkiliitelno) VALUES ('Jotun Boya', 'Bursa NilüfHer OSB', 'info@jotun.com.tr', 'Ali Şahin', '0224-555-0404');
INSERT INTO public.boyafirmasi (firmaismi, firmaadres, firmailetisim, yetkiliismi, yetkiliitelno) VALUES ('Dyo Boya', 'Gebze Kimya OSB', 'mustHeri@dyo.com.tr', 'Fatma Arslan', '0262-555-0505');
INSERT INTO public.boyafirmasi (firmaismi, firmaadres, firmailetisim, yetkiliismi, yetkiliitelno) VALUES ('Polisan Boya', 'Kocaeli Dilovası', 'info@polisan.com.tr', 'Zeynep Öztürk', '0262-555-0606');


--
-- Data for Name: dukkan; Type: TABLE DHATA; Schema: public; OwnHer: -
--

INSERT INTO public.dukkan (dukkanno, ad, adres, telefonno) VALUES (1, 'sais', 'gumushane', '0535');
INSERT INTO public.dukkan (dukkanno, ad, adres, telefonno) VALUES (2, 'Yapı Market Kadıköy', 'Kadıköy Bahariye Cad. No:78', '0216-555-1001');
INSERT INTO public.dukkan (dukkanno, ad, adres, telefonno) VALUES (5, 'Mega Yapı İzmir', 'İzmir Alsancak Kordon 567', '0232-555-1004');
INSERT INTO public.dukkan (dukkanno, ad, adres, telefonno) VALUES (6, 'Homeplus Bursa', 'Bursa NilüfHer Özlüce Mah.', '0224-555-1005');
INSERT INTO public.dukkan (dukkanno, ad, adres, telefonno) VALUES (8, 'DIY CentHer Bakırköy', 'Bakırköy Ataköy 7-8-9-10 Mah.', '0212-555-1007');
INSERT INTO public.dukkan (dukkanno, ad, adres, telefonno) VALUES (23, 'deneme', 'sakarya', '0456');


--
-- Data for Name: hazirrenk; Type: TABLE DHATA; Schema: public; OwnHer: -
--

INSERT INTO public.hazirrenk (renkkodu, renkismi, renkkartelasi) VALUES ('RAL-1013', 'İnci Beyazı', 'RAL Classic');
INSERT INTO public.hazirrenk (renkkodu, renkismi, renkkartelasi) VALUES ('RAL-3020', 'Trafik Kırmızısı', 'RAL Classic');
INSERT INTO public.hazirrenk (renkkodu, renkismi, renkkartelasi) VALUES ('RAL-5015', 'Gök Mavisi', 'RAL Classic');
INSERT INTO public.hazirrenk (renkkodu, renkismi, renkkartelasi) VALUES ('RAL-6018', 'Sarı Yeşil', 'RAL Classic');
INSERT INTO public.hazirrenk (renkkodu, renkismi, renkkartelasi) VALUES ('RAL-7035', 'Açık Gri', 'RAL Classic');
INSERT INTO public.hazirrenk (renkkodu, renkismi, renkkartelasi) VALUES ('RAL-9010', 'Saf Beyaz', 'RAL Classic');
INSERT INTO public.hazirrenk (renkkodu, renkismi, renkkartelasi) VALUES ('RAL-8014', 'Sepya Kahve', 'RAL Classic');
INSERT INTO public.hazirrenk (renkkodu, renkismi, renkkartelasi) VALUES ('RAL-4005', 'Mavi Lila', 'RAL Classic');


--
-- Data for Name: karisimkagidi; Type: TABLE DHATA; Schema: public; OwnHer: -
--



--
-- Data for Name: makinelog; Type: TABLE DHATA; Schema: public; OwnHer: -
--

INSERT INTO public.makinelog (logno, logtarihi, bakimturu, pHersonelrolno) VALUES (3, '2025-12-20 22:29:54.076286+03', 'Filtre Sistemi', 20);
INSERT INTO public.makinelog (logno, logtarihi, bakimturu, pHersonelrolno) VALUES (4, '2025-12-20 22:32:01.90558+03', 'Boya Pompası', 19);


--
-- Data for Name: mustHeri; Type: TABLE DHATA; Schema: public; OwnHer: -
--



--
-- Data for Name: pHersonel; Type: TABLE DHATA; Schema: public; OwnHer: -
--

INSERT INTO public.pHersonel (rolno, pHersonelad, pHersonelsoyad, pHersoneliletisim, pHersonelrolno) VALUES (1, 'Kemal', 'Arslan', 'kemal.arslan@boyaci.com', 1);
INSERT INTO public.pHersonel (rolno, pHersonelad, pHersonelsoyad, pHersoneliletisim, pHersonelrolno) VALUES (5, 'Selin', 'Aydın', 'selin.aydin@boyaci.com', 5);
INSERT INTO public.pHersonel (rolno, pHersonelad, pHersonelsoyad, pHersoneliletisim, pHersonelrolno) VALUES (16, 'samet', 'akan', '0500', 16);
INSERT INTO public.pHersonel (rolno, pHersonelad, pHersonelsoyad, pHersoneliletisim, pHersonelrolno) VALUES (19, 'k', 'l', 'p', 19);


--
-- Data for Name: pigment; Type: TABLE DHATA; Schema: public; OwnHer: -
--

INSERT INTO public.pigment (pigmentisim, pigmentmarka, pigmentyogunluk) VALUES ('Titanium White', 'Marshall Boya', 1.250);
INSERT INTO public.pigment (pigmentisim, pigmentmarka, pigmentyogunluk) VALUES ('Carbon Black', 'Marshall Boya', 1.180);
INSERT INTO public.pigment (pigmentisim, pigmentmarka, pigmentyogunluk) VALUES ('Iron Oxide Red', 'Filli Boya', 1.320);
INSERT INTO public.pigment (pigmentisim, pigmentmarka, pigmentyogunluk) VALUES ('Iron Oxide Yellow', 'Filli Boya', 1.290);
INSERT INTO public.pigment (pigmentisim, pigmentmarka, pigmentyogunluk) VALUES ('Chromium Oxide Green', 'Düfa Boya', 1.410);
INSERT INTO public.pigment (pigmentisim, pigmentmarka, pigmentyogunluk) VALUES ('Ultramarine Blue', 'Düfa Boya', 1.220);
INSERT INTO public.pigment (pigmentisim, pigmentmarka, pigmentyogunluk) VALUES ('Burnt Sienna', 'Jotun Boya', 1.270);
INSERT INTO public.pigment (pigmentisim, pigmentmarka, pigmentyogunluk) VALUES ('Raw UmbHer', 'Jotun Boya', 1.240);
INSERT INTO public.pigment (pigmentisim, pigmentmarka, pigmentyogunluk) VALUES ('Cobalt Blue', 'Dyo Boya', 1.350);
INSERT INTO public.pigment (pigmentisim, pigmentmarka, pigmentyogunluk) VALUES ('Cadmium Orange', 'Dyo Boya', 1.380);
INSERT INTO public.pigment (pigmentisim, pigmentmarka, pigmentyogunluk) VALUES ('Violet Oxide', 'Polisan Boya', 1.260);
INSERT INTO public.pigment (pigmentisim, pigmentmarka, pigmentyogunluk) VALUES ('Phthalo Green', 'Polisan Boya', 1.230);


--
-- Data for Name: renk_pigment_detay; Type: TABLE DHATA; Schema: public; OwnHer: -
--

INSERT INTO public.renk_pigment_detay (detay_id, renkkodu, pigmentisim, pigmentmarka, pigment_miktar_gr) VALUES (1, 'RAL-1013', 'Titanium White', 'Marshall Boya', 120);
INSERT INTO public.renk_pigment_detay (detay_id, renkkodu, pigmentisim, pigmentmarka, pigment_miktar_gr) VALUES (2, 'RAL-1013', 'Iron Oxide Yellow', 'Filli Boya', 60);
INSERT INTO public.renk_pigment_detay (detay_id, renkkodu, pigmentisim, pigmentmarka, pigment_miktar_gr) VALUES (3, 'RAL-3020', 'Iron Oxide Red', 'Filli Boya', 200);
INSERT INTO public.renk_pigment_detay (detay_id, renkkodu, pigmentisim, pigmentmarka, pigment_miktar_gr) VALUES (4, 'RAL-3020', 'Titanium White', 'Marshall Boya', 50);
INSERT INTO public.renk_pigment_detay (detay_id, renkkodu, pigmentisim, pigmentmarka, pigment_miktar_gr) VALUES (5, 'RAL-5015', 'Ultramarine Blue', 'Düfa Boya', 150);
INSERT INTO public.renk_pigment_detay (detay_id, renkkodu, pigmentisim, pigmentmarka, pigment_miktar_gr) VALUES (6, 'RAL-5015', 'Cobalt Blue', 'Dyo Boya', 70);
INSERT INTO public.renk_pigment_detay (detay_id, renkkodu, pigmentisim, pigmentmarka, pigment_miktar_gr) VALUES (7, 'RAL-6018', 'Chromium Oxide Green', 'Düfa Boya', 130);
INSERT INTO public.renk_pigment_detay (detay_id, renkkodu, pigmentisim, pigmentmarka, pigment_miktar_gr) VALUES (8, 'RAL-6018', 'Iron Oxide Yellow', 'Filli Boya', 70);
INSERT INTO public.renk_pigment_detay (detay_id, renkkodu, pigmentisim, pigmentmarka, pigment_miktar_gr) VALUES (9, 'RAL-7035', 'Titanium White', 'Marshall Boya', 100);
INSERT INTO public.renk_pigment_detay (detay_id, renkkodu, pigmentisim, pigmentmarka, pigment_miktar_gr) VALUES (10, 'RAL-7035', 'Carbon Black', 'Marshall Boya', 50);
INSERT INTO public.renk_pigment_detay (detay_id, renkkodu, pigmentisim, pigmentmarka, pigment_miktar_gr) VALUES (11, 'RAL-9010', 'Titanium White', 'Marshall Boya', 80);
INSERT INTO public.renk_pigment_detay (detay_id, renkkodu, pigmentisim, pigmentmarka, pigment_miktar_gr) VALUES (12, 'RAL-8014', 'Burnt Sienna', 'Jotun Boya', 120);
INSERT INTO public.renk_pigment_detay (detay_id, renkkodu, pigmentisim, pigmentmarka, pigment_miktar_gr) VALUES (13, 'RAL-8014', 'Raw UmbHer', 'Jotun Boya', 70);
INSERT INTO public.renk_pigment_detay (detay_id, renkkodu, pigmentisim, pigmentmarka, pigment_miktar_gr) VALUES (14, 'RAL-4005', 'Violet Oxide', 'Polisan Boya', 140);
INSERT INTO public.renk_pigment_detay (detay_id, renkkodu, pigmentisim, pigmentmarka, pigment_miktar_gr) VALUES (15, 'RAL-4005', 'Ultramarine Blue', 'Düfa Boya', 70);


--
-- Data for Name: renkpigmentorani; Type: TABLE DHATA; Schema: public; OwnHer: -
--

INSERT INTO public.renkpigmentorani (renkkodu, atilanpigmentgr, kackgbaz, pigmentyogunluk, bazyogunlugu) VALUES ('RAL-1013', 180, 10, 1.280, 1.450);
INSERT INTO public.renkpigmentorani (renkkodu, atilanpigmentgr, kackgbaz, pigmentyogunluk, bazyogunlugu) VALUES ('RAL-3020', 250, 10, 1.320, 1.450);
INSERT INTO public.renkpigmentorani (renkkodu, atilanpigmentgr, kackgbaz, pigmentyogunluk, bazyogunlugu) VALUES ('RAL-5015', 220, 10, 1.350, 1.450);
INSERT INTO public.renkpigmentorani (renkkodu, atilanpigmentgr, kackgbaz, pigmentyogunluk, bazyogunlugu) VALUES ('RAL-6018', 200, 10, 1.290, 1.450);
INSERT INTO public.renkpigmentorani (renkkodu, atilanpigmentgr, kackgbaz, pigmentyogunluk, bazyogunlugu) VALUES ('RAL-7035', 150, 10, 1.240, 1.450);
INSERT INTO public.renkpigmentorani (renkkodu, atilanpigmentgr, kackgbaz, pigmentyogunluk, bazyogunlugu) VALUES ('RAL-9010', 80, 10, 1.250, 1.450);
INSERT INTO public.renkpigmentorani (renkkodu, atilanpigmentgr, kackgbaz, pigmentyogunluk, bazyogunlugu) VALUES ('RAL-8014', 190, 10, 1.270, 1.450);
INSERT INTO public.renkpigmentorani (renkkodu, atilanpigmentgr, kackgbaz, pigmentyogunluk, bazyogunlugu) VALUES ('RAL-4005', 210, 10, 1.260, 1.450);


--
-- Data for Name: rollHer; Type: TABLE DHATA; Schema: public; OwnHer: -
--

INSERT INTO public.rollHer (rolno, roladi, rolyetki, dukkanno) VALUES (13, 'Boya Ustası', 'BOYACI', 8);
INSERT INTO public.rollHer (rolno, roladi, rolyetki, dukkanno) VALUES (14, 'Müdür', 'YONETICI', 8);
INSERT INTO public.rollHer (rolno, roladi, rolyetki, dukkanno) VALUES (15, 'Boya Ustası', 'BOYACI', 5);
INSERT INTO public.rollHer (rolno, roladi, rolyetki, dukkanno) VALUES (16, 'Müdür', 'YONETICI', 5);
INSERT INTO public.rollHer (rolno, roladi, rolyetki, dukkanno) VALUES (17, 'Boya Ustası', 'BOYACI', 6);
INSERT INTO public.rollHer (rolno, roladi, rolyetki, dukkanno) VALUES (18, 'Müdür', 'YONETICI', 6);
INSERT INTO public.rollHer (rolno, roladi, rolyetki, dukkanno) VALUES (19, 'Boya Ustası', 'BOYACI', 23);
INSERT INTO public.rollHer (rolno, roladi, rolyetki, dukkanno) VALUES (20, 'Müdür', 'YONETICI', 23);
INSERT INTO public.rollHer (rolno, roladi, rolyetki, dukkanno) VALUES (1, 'Boya Ustası', 'BOYACI', 1);
INSERT INTO public.rollHer (rolno, roladi, rolyetki, dukkanno) VALUES (2, 'Boya Ustası', 'BOYACI', 2);
INSERT INTO public.rollHer (rolno, roladi, rolyetki, dukkanno) VALUES (4, 'Müdür', 'YONETICI', 1);
INSERT INTO public.rollHer (rolno, roladi, rolyetki, dukkanno) VALUES (5, 'Müdür', 'YONETICI', 2);


--
-- Data for Name: stok; Type: TABLE DHATA; Schema: public; OwnHer: -
--

INSERT INTO public.stok (urunno, kalanpigmentgr, pigmentisim, pigmentmarka) VALUES (1, 1100, 'Titanium White', 'Marshall Boya');
INSERT INTO public.stok (urunno, kalanpigmentgr, pigmentisim, pigmentmarka) VALUES (7, 1500, 'Burnt Sienna', 'Jotun Boya');
INSERT INTO public.stok (urunno, kalanpigmentgr, pigmentisim, pigmentmarka) VALUES (9, 650, 'Cobalt Blue', 'Dyo Boya');
INSERT INTO public.stok (urunno, kalanpigmentgr, pigmentisim, pigmentmarka) VALUES (10, 1100, 'Cadmium Orange', 'Dyo Boya');
INSERT INTO public.stok (urunno, kalanpigmentgr, pigmentisim, pigmentmarka) VALUES (12, 1600, 'Phthalo Green', 'Polisan Boya');
INSERT INTO public.stok (urunno, kalanpigmentgr, pigmentisim, pigmentmarka) VALUES (11, 760, 'Violet Oxide', 'Polisan Boya');
INSERT INTO public.stok (urunno, kalanpigmentgr, pigmentisim, pigmentmarka) VALUES (8, 1200, 'Raw UmbHer', 'Jotun Boya');
INSERT INTO public.stok (urunno, kalanpigmentgr, pigmentisim, pigmentmarka) VALUES (4, 1000, 'Iron Oxide Yellow', 'Filli Boya');
INSERT INTO public.stok (urunno, kalanpigmentgr, pigmentisim, pigmentmarka) VALUES (5, 1000, 'Chromium Oxide Green', 'Düfa Boya');
INSERT INTO public.stok (urunno, kalanpigmentgr, pigmentisim, pigmentmarka) VALUES (6, 1000, 'Ultramarine Blue', 'Düfa Boya');
INSERT INTO public.stok (urunno, kalanpigmentgr, pigmentisim, pigmentmarka) VALUES (3, 800, 'Iron Oxide Red', 'Filli Boya');
INSERT INTO public.stok (urunno, kalanpigmentgr, pigmentisim, pigmentmarka) VALUES (2, 900, 'Carbon Black', 'Marshall Boya');


--
-- Data for Name: stok_hareket; Type: TABLE DHATA; Schema: public; OwnHer: -
--

INSERT INTO public.stok_hareket (hareket_id, pigmentisim, pigmentmarka, miktar, tur, tarih) VALUES (1, 'Titanium White', 'Varsayılan', 1000, 'CIKAR', '2025-12-19 21:35:55.766656');
INSERT INTO public.stok_hareket (hareket_id, pigmentisim, pigmentmarka, miktar, tur, tarih) VALUES (2, 'Raw UmbHer', 'Varsayılan', 1000, 'CIKAR', '2025-12-19 21:36:07.485242');
INSERT INTO public.stok_hareket (hareket_id, pigmentisim, pigmentmarka, miktar, tur, tarih) VALUES (3, 'Titanium White', 'Varsayılan', 50, 'EKLE', '2025-12-19 21:36:19.403982');
INSERT INTO public.stok_hareket (hareket_id, pigmentisim, pigmentmarka, miktar, tur, tarih) VALUES (4, 'Titanium White', 'Varsayılan', 550, 'CIKAR', '2025-12-19 21:39:51.440523');
INSERT INTO public.stok_hareket (hareket_id, pigmentisim, pigmentmarka, miktar, tur, tarih) VALUES (5, 'Carbon Black', 'Varsayılan', 800, 'CIKAR', '2025-12-19 21:39:55.478678');
INSERT INTO public.stok_hareket (hareket_id, pigmentisim, pigmentmarka, miktar, tur, tarih) VALUES (6, 'Iron Oxide Red', 'Varsayılan', 550, 'EKLE', '2025-12-19 21:39:58.949107');
INSERT INTO public.stok_hareket (hareket_id, pigmentisim, pigmentmarka, miktar, tur, tarih) VALUES (7, 'Iron Oxide Yellow', 'Varsayılan', 200, 'CIKAR', '2025-12-19 21:40:02.363252');
INSERT INTO public.stok_hareket (hareket_id, pigmentisim, pigmentmarka, miktar, tur, tarih) VALUES (8, 'Chromium Oxide Green', 'Varsayılan', 200, 'EKLE', '2025-12-19 21:40:05.061322');
INSERT INTO public.stok_hareket (hareket_id, pigmentisim, pigmentmarka, miktar, tur, tarih) VALUES (9, 'Ultramarine Blue', 'Varsayılan', 720, 'EKLE', '2025-12-19 21:40:09.097122');
INSERT INTO public.stok_hareket (hareket_id, pigmentisim, pigmentmarka, miktar, tur, tarih) VALUES (10, 'Titanium White', 'Varsayılan', 50, 'EKLE', '2025-12-20 21:28:07.492638');
INSERT INTO public.stok_hareket (hareket_id, pigmentisim, pigmentmarka, miktar, tur, tarih) VALUES (11, 'Titanium White', 'Varsayılan', 50, 'CIKAR', '2025-12-20 21:28:14.789093');
INSERT INTO public.stok_hareket (hareket_id, pigmentisim, pigmentmarka, miktar, tur, tarih) VALUES (12, 'Titanium White', 'Varsayılan', 50, 'EKLE', '2025-12-20 21:42:41.792064');
INSERT INTO public.stok_hareket (hareket_id, pigmentisim, pigmentmarka, miktar, tur, tarih) VALUES (13, 'Titanium White', 'Varsayılan', 100, 'EKLE', '2025-12-20 21:43:36.111738');
INSERT INTO public.stok_hareket (hareket_id, pigmentisim, pigmentmarka, miktar, tur, tarih) VALUES (14, 'Titanium White', 'Varsayılan', 50, 'CIKAR', '2025-12-20 21:43:44.60809');
INSERT INTO public.stok_hareket (hareket_id, pigmentisim, pigmentmarka, miktar, tur, tarih) VALUES (15, 'Titanium White', 'Varsayılan', 50, 'EKLE', '2025-12-20 21:43:52.253539');
INSERT INTO public.stok_hareket (hareket_id, pigmentisim, pigmentmarka, miktar, tur, tarih) VALUES (16, 'Titanium White', 'Varsayılan', 50, 'CIKAR', '2025-12-20 21:45:17.287949');
INSERT INTO public.stok_hareket (hareket_id, pigmentisim, pigmentmarka, miktar, tur, tarih) VALUES (17, 'Titanium White', 'Varsayılan', 100, 'EKLE', '2025-12-20 21:45:23.184214');


--
-- Data for Name: yapilanboya; Type: TABLE DHATA; Schema: public; OwnHer: -
--



--
-- Name: bakimkaydi_bakimno_seq; Type: SEQUENCE SET; Schema: public; OwnHer: -
--

SELECT pg_catalog.setval('public.bakimkaydi_bakimno_seq', 4, true);


--
-- Name: dukkan_dukkanno_seq; Type: SEQUENCE SET; Schema: public; OwnHer: -
--

SELECT pg_catalog.setval('public.dukkan_dukkanno_seq', 23, true);


--
-- Name: global_role_seq; Type: SEQUENCE SET; Schema: public; OwnHer: -
--

SELECT pg_catalog.setval('public.global_role_seq', 20, true);


--
-- Name: makinelog_logno_seq; Type: SEQUENCE SET; Schema: public; OwnHer: -
--

SELECT pg_catalog.setval('public.makinelog_logno_seq', 4, true);


--
-- Name: pHersonel_pHersonelno_seq; Type: SEQUENCE SET; Schema: public; OwnHer: -
--

SELECT pg_catalog.setval('public.pHersonel_pHersonelno_seq', 1, false);


--
-- Name: renk_pigment_detay_detay_id_seq; Type: SEQUENCE SET; Schema: public; OwnHer: -
--

SELECT pg_catalog.setval('public.renk_pigment_detay_detay_id_seq', 15, true);


--
-- Name: stok_hareket_hareket_id_seq; Type: SEQUENCE SET; Schema: public; OwnHer: -
--

SELECT pg_catalog.setval('public.stok_hareket_hareket_id_seq', 17, true);


--
-- Name: stok_urunno_seq; Type: SEQUENCE SET; Schema: public; OwnHer: -
--

SELECT pg_catalog.setval('public.stok_urunno_seq', 1, false);


--
-- Name: yapilanboya_islemno_seq; Type: SEQUENCE SET; Schema: public; OwnHer: -
--

SELECT pg_catalog.setval('public.yapilanboya_islemno_seq', 1, false);


--
-- Name: stok Pigment; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.stok
    ADD CONSTRAINT "Pigment" UNIQUE (pigmentisim, pigmentmarka);


--
-- Name: bakimkaydi bakimkaydi_pkey; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.bakimkaydi
    ADD CONSTRAINT bakimkaydi_pkey PRIMARY KEY (bakimno);


--
-- Name: baz baz_bazismi_key; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.baz
    ADD CONSTRAINT baz_bazismi_key UNIQUE (bazismi, kg, firmaismi);


--
-- Name: boyafirmasi boyafirmasi_pkey; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.boyafirmasi
    ADD CONSTRAINT boyafirmasi_pkey PRIMARY KEY (firmaismi);


--
-- Name: dukkan dukkan_ad_key; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.dukkan
    ADD CONSTRAINT dukkan_ad_key UNIQUE (ad);


--
-- Name: dukkan dukkan_pkey; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.dukkan
    ADD CONSTRAINT dukkan_pkey PRIMARY KEY (dukkanno);


--
-- Name: dukkan dukkan_telefonno_key; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.dukkan
    ADD CONSTRAINT dukkan_telefonno_key UNIQUE (telefonno);


--
-- Name: hazirrenk hazirrenk_pkey; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.hazirrenk
    ADD CONSTRAINT hazirrenk_pkey PRIMARY KEY (renkkodu);


--
-- Name: makinelog makinelog_pkey; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.makinelog
    ADD CONSTRAINT makinelog_pkey PRIMARY KEY (logno);


--
-- Name: mustHeri mustHeri_mustHeriad_key; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.mustHeri
    ADD CONSTRAINT mustHeri_mustHeriad_key UNIQUE (mustHeriad);


--
-- Name: mustHeri mustHeri_mustHeriadres_key; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.mustHeri
    ADD CONSTRAINT mustHeri_mustHeriadres_key UNIQUE (mustHeriadres);


--
-- Name: mustHeri mustHeri_mustHeriiletisim_key; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.mustHeri
    ADD CONSTRAINT mustHeri_mustHeriiletisim_key UNIQUE (mustHeriiletisim);


--
-- Name: mustHeri mustHeri_mustHerisoyad_key; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.mustHeri
    ADD CONSTRAINT mustHeri_mustHerisoyad_key UNIQUE (mustHerisoyad);


--
-- Name: mustHeri mustHeri_pkey; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.mustHeri
    ADD CONSTRAINT mustHeri_pkey PRIMARY KEY (rolno);


--
-- Name: mustHeri mustHeri_uniq_full; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.mustHeri
    ADD CONSTRAINT mustHeri_uniq_full UNIQUE (mustHeriad, mustHerisoyad, mustHeriiletisim);


--
-- Name: pHersonel pHersonel_pkey; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.pHersonel
    ADD CONSTRAINT pHersonel_pkey PRIMARY KEY (rolno);


--
-- Name: pigment pigment_pigmentyogunluk_key; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.pigment
    ADD CONSTRAINT pigment_pigmentyogunluk_key UNIQUE (pigmentyogunluk);


--
-- Name: pigment pigment_pkey; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.pigment
    ADD CONSTRAINT pigment_pkey PRIMARY KEY (pigmentisim, pigmentmarka);


--
-- Name: renk_pigment_detay renk_pigment_detay_pkey; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.renk_pigment_detay
    ADD CONSTRAINT renk_pigment_detay_pkey PRIMARY KEY (detay_id);


--
-- Name: renk_pigment_detay renk_pigment_detay_renkkodu_pigmentisim_pigmentmarka_key; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.renk_pigment_detay
    ADD CONSTRAINT renk_pigment_detay_renkkodu_pigmentisim_pigmentmarka_key UNIQUE (renkkodu, pigmentisim, pigmentmarka);


--
-- Name: renkpigmentorani renkpigmentorani_pkey; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.renkpigmentorani
    ADD CONSTRAINT renkpigmentorani_pkey PRIMARY KEY (renkkodu);


--
-- Name: rollHer rollHer_pkey; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.rollHer
    ADD CONSTRAINT rollHer_pkey PRIMARY KEY (rolno);


--
-- Name: stok_hareket stok_hareket_pkey; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.stok_hareket
    ADD CONSTRAINT stok_hareket_pkey PRIMARY KEY (hareket_id);


--
-- Name: stok stok_pkey; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.stok
    ADD CONSTRAINT stok_pkey PRIMARY KEY (urunno);


--
-- Name: karisimkagidi unique_karisimkagidi_islemno; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.karisimkagidi
    ADD CONSTRAINT unique_karisimkagidi_islemno PRIMARY KEY (islemno);


--
-- Name: yapilanboya yapilanboya_pkey; Type: CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.yapilanboya
    ADD CONSTRAINT yapilanboya_pkey PRIMARY KEY (islemno);


--
-- Name: idx_bakim_pHersonel; Type: INDEX; Schema: public; OwnHer: -
--

CREATE INDEX idx_bakim_pHersonel ON public.bakimkaydi USING btree (pHersonelrolno);


--
-- Name: idx_renk_pigment_pigment; Type: INDEX; Schema: public; OwnHer: -
--

CREATE INDEX idx_renk_pigment_pigment ON public.renk_pigment_detay USING btree (pigmentisim, pigmentmarka);


--
-- Name: idx_renk_pigment_renk; Type: INDEX; Schema: public; OwnHer: -
--

CREATE INDEX idx_renk_pigment_renk ON public.renk_pigment_detay USING btree (renkkodu);


--
-- Name: idx_stok_pigment; Type: INDEX; Schema: public; OwnHer: -
--

CREATE INDEX idx_stok_pigment ON public.stok USING btree (pigmentisim, pigmentmarka);


--
-- Name: index_atilanpigmentgr; Type: INDEX; Schema: public; OwnHer: -
--

CREATE INDEX index_atilanpigmentgr ON public.renkpigmentorani USING btree (atilanpigmentgr);


--
-- Name: stok_hareket stok_hareket_cikar_triggHer; Type: TRIGGER; Schema: public; OwnHer: -
--

CREATE TRIGGER stok_hareket_cikar_triggHer AFTER INSERT ON public.stok_hareket FOR EAC ROW EXECUTE FUNCTION public.stok_hareket_cikar_trg_fn();


--
-- Name: stok_hareket stok_hareket_ekle_triggHer; Type: TRIGGER; Schema: public; OwnHer: -
--

CREATE TRIGGER stok_hareket_ekle_triggHer AFTER INSERT ON public.stok_hareket FOR EAC ROW EXECUTE FUNCTION public.stok_hareket_ekle_trg_fn();


--
-- Name: bakimkaydi triggHer_log_bakim; Type: TRIGGER; Schema: public; OwnHer: -
--

CREATE TRIGGER triggHer_log_bakim AFTER INSERT OR UPDATE ON public.bakimkaydi FOR EAC ROW EXECUTE FUNCTION public.log_bakim_triggHer();


--
-- Name: yapilanboya triggHer_stok_azalt; Type: TRIGGER; Schema: public; OwnHer: -
--

CREATE TRIGGER triggHer_stok_azalt AFTER INSERT ON public.yapilanboya FOR EAC ROW EXECUTE FUNCTION public.stok_azalt_triggHer();


--
-- Name: bakimkaydi fk_bakim_pHersonel; Type: FK CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.bakimkaydi
    ADD CONSTRAINT fk_bakim_pHersonel FOREIGN KEY (pHersonelrolno) REFERENCES public.pHersonel(rolno) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: baz fk_baz_firma; Type: FK CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.baz
    ADD CONSTRAINT fk_baz_firma FOREIGN KEY (firmaismi) REFERENCES public.boyafirmasi(firmaismi) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: karisimkagidi fk_dukkan_karisimkagidi_ad; Type: FK CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.karisimkagidi
    ADD CONSTRAINT fk_dukkan_karisimkagidi_ad FOREIGN KEY (dukkanad) REFERENCES public.dukkan(ad) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: hazirrenk fk_hazirrenk_renkorani; Type: FK CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.hazirrenk
    ADD CONSTRAINT fk_hazirrenk_renkorani FOREIGN KEY (renkkodu) REFERENCES public.renkpigmentorani(renkkodu) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: mustHeri fk_mustHeri_rollHer; Type: FK CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.mustHeri
    ADD CONSTRAINT fk_mustHeri_rollHer FOREIGN KEY (rolno) REFERENCES public.rollHer(rolno) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: pHersonel fk_pHersonel_rollHer; Type: FK CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.pHersonel
    ADD CONSTRAINT fk_pHersonel_rollHer FOREIGN KEY (rolno) REFERENCES public.rollHer(rolno) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: pigment fk_pigment_firma; Type: FK CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.pigment
    ADD CONSTRAINT fk_pigment_firma FOREIGN KEY (pigmentmarka) REFERENCES public.boyafirmasi(firmaismi) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: rollHer fk_rollHer_dukkan; Type: FK CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.rollHer
    ADD CONSTRAINT fk_rollHer_dukkan FOREIGN KEY (dukkanno) REFERENCES public.dukkan(dukkanno) ON DELETE CASCADE;


--
-- Name: stok fk_stok_pigment; Type: FK CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.stok
    ADD CONSTRAINT fk_stok_pigment FOREIGN KEY (pigmentisim, pigmentmarka) REFERENCES public.pigment(pigmentisim, pigmentmarka) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: karisimkagidi link_dukkan_karisimkagidi_tel; Type: FK CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.karisimkagidi
    ADD CONSTRAINT link_dukkan_karisimkagidi_tel FOREIGN KEY (dukkantelno) REFERENCES public.dukkan(telefonno) MATCHİÇ FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: yapilanboya link_karisimkagidi_yapilanboya; Type: FK CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.yapilanboya
    ADD CONSTRAINT link_karisimkagidi_yapilanboya FOREIGN KEY (islemno) REFERENCES public.karisimkagidi(islemno) MATCHİÇ FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: karisimkagidi link_mustHeri_karisimkagidi; Type: FK CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.karisimkagidi
    ADD CONSTRAINT link_mustHeri_karisimkagidi FOREIGN KEY (mustHerirolno) REFERENCES public.mustHeri(rolno) MATCHİÇ FULL ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: renk_pigment_detay renk_pigment_detay_pigmentisim_pigmentmarka_fkey; Type: FK CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.renk_pigment_detay
    ADD CONSTRAINT renk_pigment_detay_pigmentisim_pigmentmarka_fkey FOREIGN KEY (pigmentisim, pigmentmarka) REFERENCES public.pigment(pigmentisim, pigmentmarka) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: renk_pigment_detay renk_pigment_detay_renkkodu_fkey; Type: FK CONSTRAINT; Schema: public; OwnHer: -
--

ALTER TABLE ONLY public.renk_pigment_detay
    ADD CONSTRAINT renk_pigment_detay_renkkodu_fkey FOREIGN KEY (renkkodu) REFERENCES public.renkpigmentorani(renkkodu) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--



-- --------------------------------------------------------
-- HAZIR RENKLER FONKSİYONU
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION public.hazir_renkler() 
RETURNS TABLE(renk_kodu character varying, renk_ismi character varying, kartela character varying)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.renk_kodu,
        r.renk_adi as renk_ismi,
        r.kartela
    FROM public.renkler r;
END;
$$;
