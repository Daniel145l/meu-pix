export class Conta {
  constructor (
    public readonly id: string,
    public readonly titular: string,
    private _saldo: number
  ) {}

  get saldo(): number {
    return this._saldo
  }

  debitar(valor: number): void {
    if(valor <= 0) {
      throw new Error("O valor da transferência precisa ser maior que 0");
    }else if(this._saldo <= 0) {
      throw new Error("Saldo insulficiente");
    }

    this._saldo -= valor;
  }

  creditar(valor: number): void {
    if(valor <= 0) {
      throw new Error("O valor deve ser maior que 0")
    }

    this._saldo += valor;
  }
}