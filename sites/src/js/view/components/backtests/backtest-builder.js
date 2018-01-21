import React              from "react"

import AbstractComponent    from "../widgets/abstract-component"
import DateFormatter        from "../../../viewmodel/utils/date-formatter"
import AgentSettingEditor   from "../agents/agent-setting-editor"
import RangeSelector        from "../widgets/range-selector"
import PairSelector         from "../widgets/pair-selector"
import LoadingImage         from "../widgets/loading-image"
import TickIntervalSelector from "./tick-interval-selector"

import TextField from "material-ui/TextField"
import RaisedButton from "material-ui/RaisedButton"

const keys = new Set([
  "name", "memo", "balance", "spread",
  "nameError", "memoError", "balanceError", "spreadError",
  "isSaving"
]);

export default class BacktestBuilder extends AbstractComponent {

  constructor(props) {
    super(props);
    this.state = {
      loading: true
    };
  }

  componentWillMount() {
    this.model().initialize().then(() => {
      this.registerPropertyChangeListener(this.model(), keys);
      const state = this.collectInitialState(this.model(), keys);
      state.loading = false;
      this.setState(state);
    });
  }

  render() {
    if (this.state.loading) {
      return <div className="backtest-builder center-information loading">
        <LoadingImage left={-20}/>
      </div>;
    }
    return (
      <div className="backtest-builder">
        <div className="top-button">
          <RaisedButton
            label="以下の設定でバックテストを開始"
            primary={true}
            disabled={this.state.isSaving}
            onClick={this.registerBacktest.bind(this)}
            style={{width:"300px"}}
          />
          <span className="loading-for-button-action">
            {this.state.isSaving ? <LoadingImage size={20} /> : null}
          </span>
        </div>
        <div className="inputs table">
          <div className="item">
            <div className="label">バックテスト名</div>
            <div className="input">
              <TextField
                ref="name"
                hintText="バックテストの名前"
                defaultValue={this.state.name}
                errorText={this.state.nameError}/>
            </div>
          </div>
          <div className="item">
            <div className="label">テスト期間</div>
            <div className="input">
              <RangeSelector
                ref="rangeSelector"
                model={this.model().rangeSelectorModel} />
            </div>
          </div>
          <div className="item">
            <div className="label">初期資金</div>
            <div className="input">
              <TextField
                ref="balance"
                hintText="初期資金"
                defaultValue={this.state.balance}
                errorText={this.state.balanceError} />
            </div>
          </div>
          <div className="item">
            <div className="label">レート間隔</div>
            <div className="input">
              <TickIntervalSelector
                model={this.model()} />
              <ul className="desc">
                <li>エージェントの <code>next_tick(tick)</code> が呼び出される間隔を指定します。</li>
                <li>1時間や1日にすることでテストの所要時間を大幅に削減できますが、その分、精度は落ちるのでご注意ください。</li>
              </ul>
            </div>
          </div>
          <div className="item">
            <div className="label">メモ</div>
            <div className="input">
              <TextField
                ref="memo"
                multiLine={true}
                hintText="メモ"
                defaultValue={this.state.memo}
                errorText={this.state.memoError}
                style={{
                  width: "600px"
                }} />
            </div>
          </div>
          <div className="item">
            <div className="label">スプレッド</div>
            <div className="input">
              <TextField
                ref="spread"
                hintText="スプレッド"
                defaultValue={this.state.spread}
                errorText={this.state.spreadError} />
            </div>
          </div>
        </div>
        <div  className="inputs">
          <div className="item">
            <div className="label">使用する通貨ペア</div>
            <ul className="desc">
              <li>バックテストで使用する通貨ペアを選択してください。</li>
              <li>通貨ペアは最大5つまで選択できます。</li>
              <li>利用する通貨ペアが増えると、バックテストの所要時間も増加しますのでご注意ください。</li>
            </ul>
            <PairSelector
              ref="pairSelector"
              model={this.model().pairSelectorModel} />
          </div>
          <div className="item horizontal">
            <div className="label">エージェント</div>
            <ul className="desc">
              <li>バックテストで動作させるエージェントを設定します。</li>
            </ul>
            <AgentSettingEditor
              ref="agentSettingEditor"
              model={this.model().agentSettingBuilder}/>
          </div>
        </div>
      </div>
    );
  }

  registerBacktest() {
    this.refs.agentSettingEditor.applyAgentConfiguration();
    this.refs.rangeSelector.applySetting();

    const builder = this.model();
    builder.name = this.refs.name.getValue();
    builder.memo = this.refs.memo.getValue();
    builder.balance  = this.refs.balance.getValue();
    builder.spread = this.refs.spread.getValue();

    if (!builder.validate()) return;

    builder.build().then(
      (test) => this.context.router.push({
        pathname:"/backtests/list/" + test.id
      })
    );
  }

  model() {
    return this.props.model;
  }
}
BacktestBuilder.propTypes = {
  model: React.PropTypes.object.isRequired
};
BacktestBuilder.defaultProps = {
};
BacktestBuilder.contextTypes = {
  router: React.PropTypes.object
};
