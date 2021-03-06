
import Validators from "src/utils/validation/validators"

describe("Validators", () => {

  const matchers = {
    toBeValidationError(util, customEqualityTesters) {
      return {
        compare(actual, expected) {
          try {
            actual();
            return { pass: false};
          } catch (e) {
            return { pass: e.code === expected };
          }
        }
      };
    },
    notToBeError(util, customEqualityTesters) {
      return {
        compare(actual, expected) {
          try {
            actual();
            return { pass: true};
          } catch (e) {
            throw e;
          }
        }
      };
    }
  };

  function createStringOfLength(seed, length) {
    let string = "";
    for( let i=0; i<length; i++) {
      string = string + seed;
    }
    return string;
  }

  beforeEach(() => jasmine.addMatchers(matchers));

  describe("backtest.name", () => {
    it("一般的な入力値", () => {
      expect( () => {
        Validators.backtest.name.validate("松山太郎");
      }).notToBeError();
      expect( () => {
        Validators.backtest.name.validate("松山 太郎");
      }).notToBeError();
      expect( () => {
        Validators.backtest.name.validate("松山　太郎");
      }).notToBeError();
    });
    it("200文字まで入力可能", () => {
      expect( () => {
        Validators.backtest.name.validate(createStringOfLength("a", 200));
      }).notToBeError();
      expect( () => {
        Validators.backtest.name.validate(createStringOfLength("あ", 200));
      }).notToBeError();
      expect( () => {
        Validators.backtest.name.validate(createStringOfLength("a", 201));
      }).toBeValidationError("MAX_LENGTH");
      expect( () => {
        Validators.backtest.name.validate(createStringOfLength("あ", 201));
      }).toBeValidationError("MAX_LENGTH");
    });
    it("入力必須", () => {
      expect( () => {
        Validators.backtest.name.validate("");
      }).toBeValidationError("NOT_NULL");
      expect( () => {
        Validators.backtest.name.validate(null);
      }).toBeValidationError("NOT_NULL");
      expect( () => {
        Validators.backtest.name.validate(undefined);
      }).toBeValidationError("NOT_NULL");
    });
    it("コントロールコードは入力不可", () => {
      expect( () => {
        Validators.backtest.name.validate("abc\u0002de");
      }).toBeValidationError("CONTROL_CODE");
    });
  });


  describe("mail", () => {
    it("一般的な入力値", () => {
      expect( () => {
        Validators.mailAddress.validate("foo@var.com");
      }).notToBeError();
      expect( () => {
        Validators.mailAddress.validate("foo+1_-aa@var.com");
      }).notToBeError();
      expect( () => {
        Validators.mailAddress.validate("テスト@日本語.com");
      }).notToBeError();
    });
    it("一部の記号は不可", () => {
      expect( () => {
        Validators.mailAddress.validate("foo[@var.com");
      }).toBeValidationError("PROHIBITED_CHARACTER");
      expect( () => {
        Validators.mailAddress.validate("foo\\@var.com");
      }).toBeValidationError("PROHIBITED_CHARACTER");
      expect( () => {
        Validators.mailAddress.validate("foo!@var.com");
      }).toBeValidationError("PROHIBITED_CHARACTER");
    });
    it("100文字まで入力可能", () => {
      expect( () => {
        Validators.mailAddress.validate("a@bcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcde.com");
      }).notToBeError();
      expect( () => {
        Validators.mailAddress.validate("a@bcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdea.com");
      }).toBeValidationError("MAX_LENGTH");
    });
    it("入力必須", () => {
      expect( () => {
        Validators.mailAddress.validate("");
      }).toBeValidationError("NOT_NULL");
      expect( () => {
        Validators.mailAddress.validate(null);
      }).toBeValidationError("NOT_NULL");
      expect( () => {
        Validators.mailAddress.validate(undefined);
      }).toBeValidationError("NOT_NULL");
    });
    it("コントロールコードは入力不可", () => {
      expect( () => {
        Validators.mailAddress.validate("090\u0002789");
      }).toBeValidationError("CONTROL_CODE");
    });
  });

  describe("password", () => {
    it("一般的な入力値", () => {
      expect( () => {
        Validators.password.validate("abc&1234");
      }).notToBeError();
    });
    it("一部の記号は不可", () => {
      expect( () => {
        Validators.password.validate("abc'123");
      }).toBeValidationError("PROHIBITED_CHARACTER");
      expect( () => {
        Validators.password.validate("\\123");
      }).toBeValidationError("PROHIBITED_CHARACTER");
      expect( () => {
        Validators.password.validate("abc ");
      }).toBeValidationError("PROHIBITED_CHARACTER");
    });
    it("ひらがなや漢字は不可", () => {
      expect( () => {
        Validators.password.validate("あいうえお");
      }).toBeValidationError("NOT_ALPHABET");
      expect( () => {
        Validators.password.validate("漢字漢字");
      }).toBeValidationError("NOT_ALPHABET");
    });
    it("16文字まで入力可能", () => {
      expect( () => {
        Validators.password.validate("abcdeabcdeabcdef");
      }).notToBeError();
      expect( () => {
        Validators.password.validate("abcdeabcdeabcdefx");
      }).toBeValidationError("MAX_LENGTH");
    });
    it("4文字以上必要", () => {
      expect( () => {
        Validators.password.validate("abcd");
      }).notToBeError();
      expect( () => {
        Validators.password.validate("abc");
      }).toBeValidationError("MIN_LENGTH");
    });
    it("入力必須", () => {
      expect( () => {
        Validators.password.validate("");
      }).toBeValidationError("NOT_NULL");
      expect( () => {
        Validators.password.validate(null);
      }).toBeValidationError("NOT_NULL");
      expect( () => {
        Validators.password.validate(undefined);
      }).toBeValidationError("NOT_NULL");
    });
    it("コントロールコードは入力不可", () => {
      expect( () => {
        Validators.password.validate("090\u0002789");
      }).toBeValidationError("CONTROL_CODE");
    });
  });

  describe("serverUrl", () => {
    it("一般的な入力値", () => {
      expect( () => {
        Validators.serverUrl.validate("http://localhost:51423");
      }).notToBeError();
      expect( () => {
        Validators.serverUrl.validate("https://127.0.0.1");
      }).notToBeError();
      expect( () => {
        Validators.serverUrl.validate("http://192.168.0.100:12365/aaa");
      }).notToBeError();
      expect( () => {
        Validators.serverUrl.validate("https://foo.var.com/bbb/ccc");
      }).notToBeError();
    });
    it("入力必須", () => {
      expect( () => {
        Validators.serverUrl.validate("");
      }).toBeValidationError("NOT_NULL");
      expect( () => {
        Validators.serverUrl.validate(null);
      }).toBeValidationError("NOT_NULL");
      expect( () => {
        Validators.serverUrl.validate(undefined);
      }).toBeValidationError("NOT_NULL");
    });
    it("コントロールコードは入力不可", () => {
      expect( () => {
        Validators.serverUrl.validate("http://090\u0002789");
      }).toBeValidationError("CONTROL_CODE");
    });
    it("形式が不正", () => {
      expect( () => {
        Validators.serverUrl.validate("aaa");
      }).toBeValidationError("PATTERN");
      expect( () => {
        Validators.serverUrl.validate("ftp://");
      }).toBeValidationError("PATTERN");
      expect( () => {
        Validators.serverUrl.validate("http:/aaa/bbb");
      }).toBeValidationError("PATTERN");
      expect( () => {
        Validators.serverUrl.validate("http://");
      }).toBeValidationError("PATTERN");
      expect( () => {
        Validators.serverUrl.validate("https://");
      }).toBeValidationError("PATTERN");
    });
  });

});
