# タワークレーンの連成動力学アニメーション

- tower_crane_simulation.mp4：PowerPoint 推奨。H.264、1600×900、30 fps、約10秒。
- tower_crane_simulation.gif：960×540、ループ再生。
- preview.png：5秒時点のプレビュー。

PowerPoint：［挿入］→［ビデオ］→［このデバイス］から MP4 を選択してください。

現行の剛接合部符号修正後の保存済みシミュレーション（report/continuum/simulation.mat）を再生します。全体図の変位倍率は1倍、右上図は初期形状からの振動変位のみ10倍です。吊荷の振れ角はロープ両端を結ぶ弦の鉛直方向からの角度です。

タワー・ジブ各2モード、ロープ3要素の標準ケース。パラメータは例示用で、実機では未同定です。

再生成：python scripts/animate_continuum.py --lang ja
