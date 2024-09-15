CREATE OR REPLACE FUNCTION verificar_cpf_duplicado() 
RETURNS TRIGGER AS $$
BEGIN
   -- Verificar se o CPF foi alterado
   IF (TG_OP = 'UPDATE' AND OLD.cpf <> NEW.cpf) OR (TG_OP = 'INSERT') THEN
      -- Verificar se o novo CPF já está cadastrado
      IF (SELECT COUNT(*) FROM cliente WHERE cpf = NEW.cpf) > 0 THEN
         RAISE EXCEPTION 'CPF já cadastrado no sistema!';
      END IF;
   END IF;
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cpf_duplicado
BEFORE INSERT OR UPDATE ON cliente
FOR EACH ROW
EXECUTE FUNCTION verificar_cpf_duplicado();