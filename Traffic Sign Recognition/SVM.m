load fisheriris
X = meas;
Y = species;
Mdl = fitcecoc(X,Y);


predict(Mdl, X(1,:))