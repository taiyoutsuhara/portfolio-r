// 識別可能性を考慮
data {
  int N;
  int D;
  int K;
  matrix[N, D] X;
  int<lower = 1, upper = K> Y[N];
}

transformed data {
  vector[D] Zeros;
  Zeros = rep_vector(0, D);
}

parameters {
  matrix[D, K-1] b_raw;
}

transformed parameters {
  matrix[D, K] b;
  matrix[N, K] mu;
  // 「サービスを利用していない」を表すカテゴリの強さを0に固定するため、
  // Zerosを右端に結合する。
  b = append_col(b_raw, Zeros);
  mu = X * b;
}

model {
  for (d in 1:D)
    // normal(mean, SD)のSDに、切片と説明変数の数を代入する。
    b_raw[d,] ~ normal(0, D);
  for (n in 1:N)
    Y[n] ~ categorical_logit(mu[n,]');
}