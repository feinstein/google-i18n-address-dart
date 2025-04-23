import 'package:google_i18n_address/google_i18n_address.dart';
import 'package:test/test.dart';

void main() {
  group('ValidationRules', () {
    test('getValidationRules returns correct data for Canada', () {
      final validationRules = getValidationRules({AddressField.countryCode: 'CA'});

      expect(validationRules.countryCode, 'CA');

      // Test that country area choices include both English and French names
      expect(validationRules.countryAreaChoices, [
        (code: 'AB', name: 'Alberta'),
        (code: 'BC', name: 'British Columbia'),
        (code: 'BC', name: 'Colombie-Britannique'),
        (code: 'MB', name: 'Manitoba'),
        (code: 'NB', name: 'New Brunswick'),
        (code: 'NB', name: 'Nouveau-Brunswick'),
        (code: 'NL', name: 'Newfoundland and Labrador'),
        (code: 'NL', name: 'Terre-Neuve-et-Labrador'),
        (code: 'NT', name: 'Northwest Territories'),
        (code: 'NT', name: 'Territoires du Nord-Ouest'),
        (code: 'NS', name: 'Nouvelle-Écosse'),
        (code: 'NS', name: 'Nova Scotia'),
        (code: 'NU', name: 'Nunavut'),
        (code: 'ON', name: 'Ontario'),
        (code: 'PE', name: 'Prince Edward Island'),
        (code: 'PE', name: 'Île-du-Prince-Édouard'),
        (code: 'QC', name: 'Quebec'),
        (code: 'QC', name: 'Québec'),
        (code: 'SK', name: 'Saskatchewan'),
        (code: 'YT', name: 'Yukon'),
      ]);
    });

    test('getValidationRules returns correct data for Switzerland', () {
      final validationRules = getValidationRules({AddressField.countryCode: 'CH'});

      expect(
        validationRules.allowedFields,
        unorderedEquals([
          AddressField.companyName,
          AddressField.city,
          AddressField.postalCode,
          AddressField.streetAddress,
          AddressField.name,
        ]),
      );

      expect(
        validationRules.requiredFields,
        unorderedEquals([
          AddressField.city,
          AddressField.postalCode,
          AddressField.streetAddress,
        ]),
      );
    });

    test(
      'getValidationRules returns correct data for Brazil and Rio de Janeiro state',
      () {
        final validationRules = getValidationRules({
          AddressField.countryCode: 'BR',
          AddressField.countryArea: 'RJ',
          AddressField.city: 'Rio de Janeiro',
        });

        expect(validationRules.addressFormat, '%O%n%N%n%A%n%D%n%C-%S%n%Z');
        expect(validationRules.addressLatinFormat, '%O%n%N%n%A%n%D%n%C-%S%n%Z');

        expect(
          validationRules.allowedFields,
          unorderedEquals([
            AddressField.companyName,
            AddressField.name,
            AddressField.streetAddress,
            AddressField.cityArea,
            AddressField.city,
            AddressField.countryArea,
            AddressField.postalCode,
          ]),
        );

        expect(validationRules.cityAreaChoices, []);

        expect(validationRules.cityAreaType, 'neighborhood');
        expect(validationRules.cityType, 'city');
        expect(validationRules.countryAreaType, 'state');
        expect(validationRules.countryCode, 'BR');
        expect(validationRules.countryName, 'BRAZIL');

        expect(validationRules.postalCodeExamples, ['20000-000', '28999-999']);
        expect(validationRules.postalCodeMatchers, [
          RegExp(r'^\d{5}-?\d{3}$'),
          RegExp(r'^2[0-8]'),
        ]);

        expect(validationRules.postalCodeType, 'postal');
        expect(validationRules.upperFields, [
          AddressField.city,
          AddressField.countryArea,
        ]);

        expect(
          validationRules.requiredFields,
          unorderedEquals([
            AddressField.streetAddress,
            AddressField.countryArea,
            AddressField.city,
            AddressField.postalCode,
          ]),
        );

        expect(
          validationRules.countryAreaChoices,
          unorderedEquals([
            (code: 'AC', name: 'Acre'),
            (code: 'AL', name: 'Alagoas'),
            (code: 'AP', name: 'Amapá'),
            (code: 'AM', name: 'Amazonas'),
            (code: 'BA', name: 'Bahia'),
            (code: 'CE', name: 'Ceará'),
            (code: 'DF', name: 'Distrito Federal'),
            (code: 'ES', name: 'Espírito Santo'),
            (code: 'GO', name: 'Goiás'),
            (code: 'MA', name: 'Maranhão'),
            (code: 'MT', name: 'Mato Grosso'),
            (code: 'MS', name: 'Mato Grosso do Sul'),
            (code: 'MG', name: 'Minas Gerais'),
            (code: 'PA', name: 'Pará'),
            (code: 'PB', name: 'Paraíba'),
            (code: 'PR', name: 'Paraná'),
            (code: 'PE', name: 'Pernambuco'),
            (code: 'PI', name: 'Piauí'),
            (code: 'RJ', name: 'Rio de Janeiro'),
            (code: 'RN', name: 'Rio Grande do Norte'),
            (code: 'RS', name: 'Rio Grande do Sul'),
            (code: 'RO', name: 'Rondônia'),
            (code: 'RR', name: 'Roraima'),
            (code: 'SC', name: 'Santa Catarina'),
            (code: 'SP', name: 'São Paulo'),
            (code: 'SE', name: 'Sergipe'),
            (code: 'TO', name: 'Tocantins'),
          ]),
        );

        expect(
          validationRules.cityChoices,
          unorderedEquals([
            (code: 'Angra dos Reis', name: 'Angra dos Reis'),
            (code: 'Aperibé', name: 'Aperibé'),
            (code: 'Araruama', name: 'Araruama'),
            (code: 'Areal', name: 'Areal'),
            (code: 'Armação dos Búzios', name: 'Armação dos Búzios'),
            (code: 'Arraial do Cabo', name: 'Arraial do Cabo'),
            (code: 'Bacaxá', name: 'Bacaxá'),
            (code: 'Barra do Piraí', name: 'Barra do Piraí'),
            (code: 'Barra Mansa', name: 'Barra Mansa'),
            (code: 'Belford Roxo', name: 'Belford Roxo'),
            (code: 'Bom Jardim', name: 'Bom Jardim'),
            (code: 'Bom Jesus do Itabapoana', name: 'Bom Jesus do Itabapoana'),
            (code: 'Cabo Frio', name: 'Cabo Frio'),
            (code: 'Cachoeiras de Macacu', name: 'Cachoeiras de Macacu'),
            (code: 'Cambuci', name: 'Cambuci'),
            (code: 'Campos dos Goytacazes', name: 'Campos dos Goytacazes'),
            (code: 'Cantagalo', name: 'Cantagalo'),
            (code: 'Carapebus', name: 'Carapebus'),
            (code: 'Cardoso Moreira', name: 'Cardoso Moreira'),
            (code: 'Carmo', name: 'Carmo'),
            (code: 'Casimiro de Abreu', name: 'Casimiro de Abreu'),
            (code: 'Comendador Levy Gasparian', name: 'Comendador Levy Gasparian'),
            (code: 'Conceição de Macabu', name: 'Conceição de Macabu'),
            (code: 'Cordeiro', name: 'Cordeiro'),
            (code: 'Duas Barras', name: 'Duas Barras'),
            (code: 'Duque de Caxias', name: 'Duque de Caxias'),
            (code: 'Engenheiro Paulo de Frontin', name: 'Engenheiro Paulo de Frontin'),
            (code: 'Guapimirim', name: 'Guapimirim'),
            (code: 'Iguaba Grande', name: 'Iguaba Grande'),
            (code: 'Itaboraí', name: 'Itaboraí'),
            (code: 'Itaguaí', name: 'Itaguaí'),
            (code: 'Italva', name: 'Italva'),
            (code: 'Itaocara', name: 'Itaocara'),
            (code: 'Itaperuna', name: 'Itaperuna'),
            (code: 'Itatiaia', name: 'Itatiaia'),
            (code: 'Japeri', name: 'Japeri'),
            (code: 'Laje do Muriaé', name: 'Laje do Muriaé'),
            (code: 'Macaé', name: 'Macaé'),
            (code: 'Macuco', name: 'Macuco'),
            (code: 'Magé', name: 'Magé'),
            (code: 'Mangaratiba', name: 'Mangaratiba'),
            (code: 'Maricá', name: 'Maricá'),
            (code: 'Mendes', name: 'Mendes'),
            (code: 'Mesquita', name: 'Mesquita'),
            (code: 'Miguel Pereira', name: 'Miguel Pereira'),
            (code: 'Miracema', name: 'Miracema'),
            (code: 'Natividade', name: 'Natividade'),
            (code: 'Nilópolis', name: 'Nilópolis'),
            (code: 'Niterói', name: 'Niterói'),
            (code: 'Nova Friburgo', name: 'Nova Friburgo'),
            (code: 'Nova Iguaçu', name: 'Nova Iguaçu'),
            (code: 'Paracambi', name: 'Paracambi'),
            (code: 'Paraíba do Sul', name: 'Paraíba do Sul'),
            (code: 'Paraty', name: 'Paraty'),
            (code: 'Paty do Alferes', name: 'Paty do Alferes'),
            (code: 'Petrópolis', name: 'Petrópolis'),
            (code: 'Pinheiral', name: 'Pinheiral'),
            (code: 'Piraí', name: 'Piraí'),
            (code: 'Porciúncula', name: 'Porciúncula'),
            (code: 'Porto Real', name: 'Porto Real'),
            (code: 'Quatis', name: 'Quatis'),
            (code: 'Queimados', name: 'Queimados'),
            (code: 'Quissamã', name: 'Quissamã'),
            (code: 'Resende', name: 'Resende'),
            (code: 'Rio Bonito', name: 'Rio Bonito'),
            (code: 'Rio Claro', name: 'Rio Claro'),
            (code: 'Rio das Flores', name: 'Rio das Flores'),
            (code: 'Rio das Ostras', name: 'Rio das Ostras'),
            (code: 'Rio de Janeiro', name: 'Rio de Janeiro'),
            (code: 'Santa Maria Madalena', name: 'Santa Maria Madalena'),
            (code: 'Santo Antônio de Pádua', name: 'Santo Antônio de Pádua'),
            (code: 'São Fidélis', name: 'São Fidélis'),
            (code: 'São Francisco de Itabapoana', name: 'São Francisco de Itabapoana'),
            (code: 'São Gonçalo', name: 'São Gonçalo'),
            (code: 'São João da Barra', name: 'São João da Barra'),
            (code: 'São João de Meriti', name: 'São João de Meriti'),
            (code: 'São José de Ubá', name: 'São José de Ubá'),
            (
              code: 'São José do Vale do Rio Preto',
              name: 'São José do Vale do Rio Preto',
            ),
            (code: 'São Pedro da Aldeia', name: 'São Pedro da Aldeia'),
            (code: 'São Sebastião do Alto', name: 'São Sebastião do Alto'),
            (code: 'Sapucaia', name: 'Sapucaia'),
            (code: 'Saquarema', name: 'Saquarema'),
            (code: 'Seropédica', name: 'Seropédica'),
            (code: 'Silva Jardim', name: 'Silva Jardim'),
            (code: 'Sumidouro', name: 'Sumidouro'),
            (code: 'Tanguá', name: 'Tanguá'),
            (code: 'Teresópolis', name: 'Teresópolis'),
            (code: 'Trajano de Morais', name: 'Trajano de Morais'),
            (code: 'Três Rios', name: 'Três Rios'),
            (code: 'Valença', name: 'Valença'),
            (code: 'Varre-Sai', name: 'Varre-Sai'),
            (code: 'Vassouras', name: 'Vassouras'),
            (code: 'Volta Redonda', name: 'Volta Redonda'),
          ]),
        );
      },
    );

    test('getValidationRules returns correct city options for China city', () {
      final validationRules = getValidationRules({
        AddressField.countryCode: 'CN',
        AddressField.countryArea: 'Yunnan Sheng',
        AddressField.city: 'Lincang Shi',
      });

      expect(
        validationRules.cityChoices,
        unorderedEquals([
          (code: '保山市', name: 'Baoshan Shi'),
          (code: '保山市', name: '保山市'),
          (code: '楚雄彝族自治州', name: 'Chuxiong Yizu Zizhizhou'),
          (code: '楚雄彝族自治州', name: 'Chuxiong Zhou'),
          (code: '楚雄彝族自治州', name: '楚雄州'),
          (code: '大理白族自治州', name: 'Dali Baizu Zizhizhou'),
          (code: '大理白族自治州', name: 'Dali Zhou'),
          (code: '大理白族自治州', name: '大理州'),
          (code: '德宏傣族景颇族自治州', name: 'Dehong Daizu Jingpozu Zizhizhou'),
          (code: '德宏傣族景颇族自治州', name: 'Dehong Zhou'),
          (code: '德宏傣族景颇族自治州', name: '德宏州'),
          (code: '迪庆藏族自治州', name: 'Dêqên Zangzu Zizhizhou'),
          (code: '迪庆藏族自治州', name: 'Dêqên Zhou'),
          (code: '迪庆藏族自治州', name: '迪庆州'),
          (code: '红河哈尼族彝族自治州', name: 'Honghe Hanizu Yizu Zizhizhou'),
          (code: '红河哈尼族彝族自治州', name: 'Honghe Zhou'),
          (code: '红河哈尼族彝族自治州', name: '红河州'),
          (code: '昆明市', name: 'Kunming Shi'),
          (code: '昆明市', name: '昆明市'),
          (code: '丽江市', name: 'Lijiang Shi'),
          (code: '丽江市', name: '丽江市'),
          (code: '临沧市', name: 'Lincang Shi'),
          (code: '临沧市', name: '临沧市'),
          (code: '怒江傈僳族自治州', name: 'Nujiang Lisuzu Zizhizhou'),
          (code: '怒江傈僳族自治州', name: 'Nujiang Zhou'),
          (code: '怒江傈僳族自治州', name: '怒江州'),
          (code: '普洱市', name: 'Puer Shi'),
          (code: '普洱市', name: '普洱市'),
          (code: '曲靖市', name: 'Qujing Shi'),
          (code: '曲靖市', name: '曲靖市'),
          (code: '文山壮族苗族自治州', name: 'Wenshan Zhou'),
          (code: '文山壮族苗族自治州', name: 'Wenshan Zhuangzu Miaozu Zizhizhou'),
          (code: '文山壮族苗族自治州', name: '文山州'),
          (code: '西双版纳傣族自治州', name: 'Xishuangbanna Daizu Zizhizhou'),
          (code: '西双版纳傣族自治州', name: 'Xishuangbanna Zhou'),
          (code: '西双版纳傣族自治州', name: '西双版纳州'),
          (code: '玉溪市', name: 'Yuxi Shi'),
          (code: '玉溪市', name: '玉溪市'),
          (code: '昭通市', name: 'Zhaotong Shi'),
          (code: '昭通市', name: '昭通市'),
        ]),
      );
    });
  });

  group('normalizeAddress', () {
    test('throws InvalidAddressError on empty address', () {
      expect(() => normalizeAddress({}), throwsA(isA<InvalidAddressError>()));
    });

    test('throws InvalidAddressError with missing fields for Argentina', () {
      expect(
        () => normalizeAddress({AddressField.countryCode: 'AR'}),
        throwsA(
          predicate(
            (e) =>
                e is InvalidAddressError &&
                e.errors.containsKey(AddressField.city) &&
                e.errors.containsKey(AddressField.streetAddress),
          ),
        ),
      );
    });

    test('throws InvalidAddressError with invalid city for China', () {
      expect(
        () => normalizeAddress({
          AddressField.countryCode: 'CN',
          AddressField.countryArea: '北京市',
          AddressField.postalCode: '100084',
          AddressField.city: 'Invalid',
          AddressField.streetAddress: '...',
        }),
        throwsA(
          predicate(
            (e) =>
                e is InvalidAddressError &&
                e.errors.containsKey(AddressField.city) &&
                e.errors[AddressField.city] == 'invalid',
          ),
        ),
      );
    });

    test('throws InvalidAddressError with invalid postal code for Germany', () {
      expect(
        () => normalizeAddress({
          AddressField.countryCode: 'DE',
          AddressField.city: 'Berlin',
          AddressField.postalCode: '77-777',
          AddressField.streetAddress: '...',
        }),
        throwsA(
          predicate(
            (e) =>
                e is InvalidAddressError &&
                e.errors.containsKey(AddressField.postalCode) &&
                e.errors[AddressField.postalCode] == 'invalid',
          ),
        ),
      );
    });

    test('normalizes a valid US address', () {
      final address = normalizeAddress({
        AddressField.countryCode: 'US',
        AddressField.countryArea: 'California',
        AddressField.city: 'Mountain View',
        AddressField.postalCode: '94043',
        AddressField.streetAddress: '1600 Amphitheatre Pkwy',
      });

      expect(address[AddressField.countryCode], 'US');
      expect(address[AddressField.countryArea], 'CA');
      expect(address[AddressField.city], 'MOUNTAIN VIEW');
      expect(address[AddressField.postalCode], '94043');
      expect(address[AddressField.streetAddress], '1600 Amphitheatre Pkwy');
    });

    test('handles address with exact matching postal code', () {
      final address = normalizeAddress({
        AddressField.countryCode: 'US',
        AddressField.countryArea: 'California',
        AddressField.city: 'Mountain View',
        AddressField.postalCode: '94043',
        AddressField.streetAddress: '1600 Amphitheatre Pkwy',
      });

      expect(address[AddressField.postalCode], '94043');
    });
  });

  group('getFieldOrder', () {
    test('returns correct field order for Poland', () {
      final fieldOrder = getFieldOrder({AddressField.countryCode: 'PL'});

      expect(fieldOrder, [
        [AddressField.name],
        [AddressField.companyName],
        [AddressField.streetAddress],
        [AddressField.postalCode, AddressField.city],
      ]);
    });

    test('returns correct field order for China', () {
      final fieldOrder = getFieldOrder({AddressField.countryCode: 'CN'});

      expect(fieldOrder, [
        [AddressField.postalCode],
        [AddressField.countryArea, AddressField.city, AddressField.cityArea],
        [AddressField.streetAddress],
        [AddressField.companyName],
        [AddressField.name],
      ]);
    });

    test('returns correct field order for Bangladesh', () {
      final fieldOrder = getFieldOrder({AddressField.countryCode: 'BD'});

      expect(fieldOrder, [
        [AddressField.name],
        [AddressField.companyName],
        [AddressField.streetAddress],
        [AddressField.city, AddressField.postalCode],
      ]);
    });

    test('returns correct field order for Saint Pierre and Miquelon', () {
      final fieldOrder = getFieldOrder({AddressField.countryCode: 'PM'});

      expect(fieldOrder, [
        [AddressField.companyName],
        [AddressField.name],
        [AddressField.streetAddress],
        [AddressField.postalCode, AddressField.city, AddressField.sortingCode],
      ]);
    });
  });
}
